package dev.tvvnc.tv_vnc.core

import kotlinx.coroutines.*
import org.junit.Assert.*
import org.junit.Test
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.URL
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

class BoundedHttpTest {
    private fun readRequest(socket: Socket): String {
        socket.soTimeout = 12_000
        val input = socket.getInputStream()
        val bytes = java.io.ByteArrayOutputStream()
        while (!bytes.toString("US-ASCII").endsWith("\r\n\r\n")) {
            val n = input.read(); check(n >= 0); bytes.write(n)
        }
        val headers = bytes.toString("US-ASCII")
        val length = Regex("(?i)Content-Length: (\\d+)").find(headers)?.groupValues?.get(1)?.toInt() ?: 0
        repeat(length) { check(input.read() >= 0) }
        return headers
    }
    private suspend fun request(server: ServerSocket, body: ByteArray? = null, limit: Int = 1024) =
        BoundedHttp.exchange(URL("http://192.0.2.123:${server.localPort}/sony/system"),
            InetAddress.getLoopbackAddress(), mapOf("X-Auth-PSK" to "synthetic-fixture"), body, limit)

    @Test fun pinsSocketAndDoesNotFollowCredentialRedirect() = runBlocking {
        ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { server ->
            val headers = CompletableFuture<String>()
            val worker = thread { server.accept().use { peer ->
                headers.complete(readRequest(peer))
                peer.getOutputStream().write("HTTP/1.1 302 Found\r\nLocation: http://example.invalid/\r\nContent-Length: 0\r\n\r\n".toByteArray())
            } }
            assertEquals(302, request(server, "{}".toByteArray()).status)
            assertTrue(headers.get(1, TimeUnit.SECONDS).contains("synthetic-fixture"))
            server.soTimeout = 250
            try { server.accept().close(); fail("redirect/replay opened another socket") } catch (_: java.net.SocketTimeoutException) { }
            worker.join()
        }
    }
    @Test fun oversizedResponseIsRejected() = runBlocking {
        ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { server ->
            val worker = thread { server.accept().use { peer ->
                readRequest(peer)
                peer.getOutputStream().write("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\n12345".toByteArray())
            } }
            try { request(server, limit = 4); fail("oversized reply accepted") }
            catch (e: LocalRequestError) { assertEquals("response_too_large", e.code) }
            worker.join()
        }
    }
    @Test fun cancellationClosesActiveRead() = runBlocking {
        ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { server ->
            val received = CompletableDeferred<Unit>()
            val eof = CompletableFuture<Int>()
            val worker = thread { server.accept().use { peer ->
                readRequest(peer); received.complete(Unit)
                eof.complete(peer.getInputStream().read())
            } }
            val pending = launch { request(server) }
            withTimeout(2000) { received.await() }
            pending.cancelAndJoin()
            assertEquals(-1, eof.get(2, TimeUnit.SECONDS))
            worker.join()
        }
    }
    @Test fun dripResponseHasWholeCallDeadlineAndIsNeverReplayed() = runBlocking {
        ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { server ->
            val worker = thread { server.accept().use { peer ->
                readRequest(peer)
                try {
                    val output = peer.getOutputStream()
                    output.write("HTTP/1.1 200 OK\r\nContent-Length: 1000\r\n\r\n".toByteArray())
                    repeat(12) { output.write(65); output.flush(); Thread.sleep(900) }
                } catch (_: java.io.IOException) { /* Client's deadline closes the socket. */ }
            } }
            val start = System.nanoTime()
            try { withTimeout(10_000) { request(server, "{}".toByteArray()) }; fail("unbounded response") }
            catch (_: HttpDeliveryUnknown) { }
            assertTrue(TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start) in 7000..9500)
            server.soTimeout = 250
            try { server.accept().close(); fail("uncertain command replayed") } catch (_: java.net.SocketTimeoutException) { }
            worker.join(3000)
            assertFalse(worker.isAlive)
        }
    }
}
