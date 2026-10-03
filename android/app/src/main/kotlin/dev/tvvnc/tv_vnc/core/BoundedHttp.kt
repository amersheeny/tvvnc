package dev.tvvnc.tv_vnc.core

import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.HttpUrl.Companion.toHttpUrl
import okio.BufferedSink
import java.io.IOException
import java.net.*
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import javax.net.SocketFactory
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

internal data class HttpReply(val status: Int, val cookies: List<String>, val bytes: ByteArray)

/** One-shot, cancellable requests. The socket is pinned to the validated
 * InetAddress (including its IPv6 interface scope); neither DNS, proxies,
 * redirects nor automatic replay may select another destination. TLS retains
 * OkHttp's normal certificate and hostname verification. */
internal object BoundedHttp {
    private val client = OkHttpClient.Builder()
        .proxy(Proxy.NO_PROXY).followRedirects(false).followSslRedirects(false)
        .retryOnConnectionFailure(false).fastFallback(false)
        .connectTimeout(4, TimeUnit.SECONDS).readTimeout(4, TimeUnit.SECONDS)
        .writeTimeout(4, TimeUnit.SECONDS).callTimeout(8, TimeUnit.SECONDS)
        .build()

    suspend fun exchange(url: URL, address: InetAddress, headers: Map<String, String>,
        body: ByteArray?, limit: Int): HttpReply = suspendCancellableCoroutine { continuation ->
        val writing = AtomicBoolean(false)
        // A zone identifier chooses an interface, not a certificate identity.
        // HttpUrl does not accept zone IDs; the pinned socket keeps the scope.
        val host = url.host.removeSurrounding("[", "]").substringBefore('%')
        val wireUrl = URL(url.protocol, host, url.port, url.file).toString().toHttpUrl()
        val port = wireUrl.port
        val request = Request.Builder().url(wireUrl).apply {
            headers.forEach { (name, value) -> header(name, value) }
            if (body != null) post(object : RequestBody() {
                override fun contentType() = (headers["Content-Type"] ?: "application/json").toMediaType()
                override fun contentLength() = body.size.toLong()
                override fun isOneShot() = true
                override fun writeTo(sink: BufferedSink) { writing.set(true); sink.write(body) }
            })
        }.build()
        val call = client.newBuilder().dns { listOf(address) }
            .socketFactory(PinnedSockets(address, port)).build().newCall(request)
        continuation.invokeOnCancellation { call.cancel() }
        call.enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                continuation.resumeWithException(if (writing.get()) HttpDeliveryUnknown() else e)
            }
            override fun onResponse(call: Call, response: Response) {
                try {
                    val reply = response.use {
                        // No need to consume an error/redirect body, which can
                        // itself stall. A rejected command is not replayed here.
                        val bytes = if (it.code !in 200..299) byteArrayOf() else {
                            val output = java.io.ByteArrayOutputStream()
                            it.body.byteStream().use { input ->
                                val buffer = ByteArray(8192)
                                while (output.size() <= limit) {
                                    val n = input.read(buffer, 0, minOf(buffer.size, limit + 1 - output.size()))
                                    if (n < 0) break
                                    output.write(buffer, 0, n)
                                }
                            }
                            if (output.size() > limit) throw LocalRequestError("response_too_large")
                            output.toByteArray()
                        }
                        HttpReply(it.code, it.headers.values("Set-Cookie"), bytes)
                    }
                    continuation.resume(reply)
                } catch (e: Exception) {
                    continuation.resumeWithException(if (e is IOException && e !is LocalRequestError && writing.get())
                        HttpDeliveryUnknown() else e)
                }
            }
        })
    }

    private class PinnedSockets(val address: InetAddress, val port: Int) : SocketFactory() {
        override fun createSocket(): Socket = object : Socket() {
            override fun connect(endpoint: SocketAddress, timeout: Int) {
                super.connect(InetSocketAddress(this@PinnedSockets.address, this@PinnedSockets.port), timeout)
            }
            override fun connect(endpoint: SocketAddress) = connect(endpoint, 0)
        }
        override fun createSocket(host: String, port: Int) = createSocket().apply { connect(InetSocketAddress(address, this@PinnedSockets.port)) }
        override fun createSocket(host: InetAddress, port: Int) = createSocket().apply { connect(InetSocketAddress(address, this@PinnedSockets.port)) }
        override fun createSocket(host: String, port: Int, local: InetAddress, localPort: Int) = createSocket().apply {
            bind(InetSocketAddress(local, localPort)); connect(InetSocketAddress(address, this@PinnedSockets.port))
        }
        override fun createSocket(host: InetAddress, port: Int, local: InetAddress, localPort: Int) = createSocket().apply {
            bind(InetSocketAddress(local, localPort)); connect(InetSocketAddress(address, this@PinnedSockets.port))
        }
    }
}
