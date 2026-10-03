package dev.tvvnc.tv_vnc.core

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import dev.tvvnc.tv_vnc.bridge.DiscoveredTv
import kotlinx.coroutines.*
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.URL
import java.util.concurrent.ConcurrentHashMap

class LanDiscovery(private val context: Context) {
    suspend fun scan(): List<DiscoveredTv> = coroutineScope {
        val devices = ConcurrentHashMap<String, DiscoveredTv>()
        val manager = context.getSystemService(NsdManager::class.java)
        val lock = (context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager)
            .createMulticastLock("tvvnc-discovery").apply { setReferenceCounted(false); acquire() }
        val listeners = mutableListOf<NsdManager.DiscoveryListener>()
        val active = java.util.concurrent.atomic.AtomicBoolean(true)
        val resolver = java.util.concurrent.ThreadPoolExecutor(1, 1, 0L, java.util.concurrent.TimeUnit.MILLISECONDS,
            java.util.concurrent.ArrayBlockingQueue(128))
        try {
            for (type in listOf("_androidtvremote2._tcp.", "_rfb._tcp.", "_tvconsole._tcp.")) {
                val listener = object : NsdManager.DiscoveryListener {
                    override fun onDiscoveryStarted(service: String) {}
                    override fun onDiscoveryStopped(service: String) {}
                    override fun onStartDiscoveryFailed(service: String, code: Int) { devices["error:$service"] = DiscoveredTv("", "", "error:$code", 0) }
                    override fun onStopDiscoveryFailed(service: String, code: Int) { android.util.Log.w("TVConsoleDiscovery", "discovery_stop_$code") }
                    override fun onServiceLost(info: NsdServiceInfo) {}
                    override fun onServiceFound(info: NsdServiceInfo) {
                        if (!active.get() || devices.size >= 128) return
                        try { resolver.execute {
                            if (!active.get()) return@execute
                            val done = java.util.concurrent.CountDownLatch(1)
                            @Suppress("DEPRECATION")
                            manager.resolveService(info, object : NsdManager.ResolveListener {
                                override fun onResolveFailed(service: NsdServiceInfo, code: Int) {
                                    android.util.Log.w("TVConsoleDiscovery", "discovery_resolve_$code"); done.countDown()
                                }
                                override fun onServiceResolved(service: NsdServiceInfo) {
                                    @Suppress("DEPRECATION") val host = service.host
                                    if (active.get() && host != null && PrivateNetwork.isLocal(host)) {
                                        val address = host.hostAddress.orEmpty()
                                        devices["$address:$type"] = DiscoveredTv(service.serviceName.take(120), address, type, service.port.toLong())
                                    }
                                    done.countDown()
                                }
                            })
                            try { done.await(2, java.util.concurrent.TimeUnit.SECONDS) }
                            catch (_: InterruptedException) { Thread.currentThread().interrupt() }
                        } } catch (_: java.util.concurrent.RejectedExecutionException) {
                            if (active.get()) android.util.Log.w("TVConsoleDiscovery", "discovery_queue_full")
                        }
                    }
                }
                listeners += listener
                manager.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, listener)
            }
            val ssdp = async(Dispatchers.IO) {
                DatagramSocket().use { socket ->
                    socket.soTimeout = 300
                    val query = "M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: ssdp:all\r\n\r\n".toByteArray()
                    socket.send(DatagramPacket(query, query.size, InetAddress.getByName("239.255.255.250"), 1900))
                    val until = System.nanoTime() + 3_000_000_000L
                    while (isActive && System.nanoTime() < until) {
                        val packet = DatagramPacket(ByteArray(8192), 8192)
                        try { socket.receive(packet) } catch (_: java.net.SocketTimeoutException) { continue }
                        val headers = String(packet.data, 0, packet.length, Charsets.UTF_8).lineSequence()
                            .filter { it.contains(':') }.associate { it.substringBefore(':').lowercase() to it.substringAfter(':').trim() }
                        val server = headers["server"].orEmpty()
                        val identifier = headers["usn"].orEmpty()
                        if (!server.contains("sony", true) && !server.contains("bravia", true) && !identifier.contains("sony", true)) continue
                        val location = headers["location"] ?: continue
                        val url = runCatching { URL(location) }.getOrNull() ?: continue
                        if (url.protocol != "http") continue
                        val address = runCatching { PrivateNetwork.resolve(url.host) }.getOrNull() ?: continue
                        devices["$address:sony"] = DiscoveredTv("BRAVIA", address, "sony", url.port.takeIf { it > 0 }?.toLong() ?: 80L)
                    }
                }
            }
            delay(4_000)
            ssdp.await()
        } finally {
            active.set(false)
            listeners.forEach { listener -> try { manager.stopServiceDiscovery(listener) }
                catch (_: Exception) { android.util.Log.w("TVConsoleDiscovery", "discovery_stop_failed") } }
            resolver.shutdownNow()
            lock.release()
        }
        devices.values.filter { it.host.isNotEmpty() }.sortedBy { it.name.lowercase() }
    }
}
