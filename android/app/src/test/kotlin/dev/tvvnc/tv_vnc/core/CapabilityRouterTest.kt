package dev.tvvnc.tv_vnc.core

import dev.tvvnc.tv_vnc.bridge.*
import kotlinx.coroutines.*
import org.junit.Assert.*
import org.junit.Test
import java.net.InetAddress

class CapabilityRouterTest {
    @Test fun queuedTapCannotActOnAReplacementConnection() = runBlocking {
        val entered = CompletableDeferred<Unit>()
        val finish = CompletableDeferred<Unit>()
        val port = object : CommandTransport {
            override val id = "remote"
            override var connectionGeneration = 1L
            var sends = 0
            override fun accepts(command: TvCommand) = true
            override suspend fun send(command: TvCommand, expectedConnection: Long): CommandOutcome {
                sends++; entered.complete(Unit); finish.await()
                return CommandOutcome(Delivery.UNKNOWN, id, "delivery_unknown")
            }
        }
        val router = CapabilityRouter({ true }) { listOf(port) }
        val first = async { router.execute(command()) }; entered.await()
        val queued = async(start = CoroutineStart.UNDISPATCHED) { router.execute(command()) }
        port.connectionGeneration++
        finish.complete(Unit); first.await()
        assertEquals("stale_session", queued.await().errorCode)
        assertEquals(1, port.sends)
    }
    @Test fun disconnectedRemoteNeverRetainsReadyStatus() {
        assertEquals(Availability.UNAVAILABLE, CapabilityRouter.liveRemoteAvailability(false, Availability.READY))
        assertEquals(Availability.NEEDS_SETUP, CapabilityRouter.liveRemoteAvailability(false, Availability.NEEDS_SETUP))
        assertEquals(Availability.READY, CapabilityRouter.liveRemoteAvailability(true, Availability.ADVERTISED))
    }
    @Test fun noUsableRouteDoesNotClaimTvUnsupported() = runBlocking {
        val outcome = CapabilityRouter({ true }) { emptyList() }.execute(command())
        assertEquals(Delivery.NOT_SENT, outcome.delivery)
        assertEquals("transport_unavailable", outcome.errorCode)
    }
    @Test fun uncertainSupportIsNotMislabelledUnsupported() {
        assertEquals(Availability.UNAVAILABLE, CapabilityRouter.bestAvailability(listOf(Availability.UNAVAILABLE, Availability.UNSUPPORTED)))
        assertEquals(Availability.UNKNOWN, CapabilityRouter.bestAvailability(listOf(Availability.UNAVAILABLE, Availability.UNKNOWN)))
        assertEquals(Availability.NEEDS_SETUP, CapabilityRouter.bestAvailability(listOf(Availability.NEEDS_SETUP, Availability.UNAVAILABLE)))
        assertEquals(Availability.READY, CapabilityRouter.bestAvailability(Availability.entries.toList()))
    }
    @Test fun diagnosticCodesPreserveStorageAndPinnedIdentityFailures() {
        val storage = LocalRequestError("credential_storage_failed")
        assertEquals("credential_storage_failed", storage.toString())
        assertEquals("credential_storage_failed", SonyTransport.safeError(storage))
        assertEquals("pin_storage_failed", SonyTransport.safeError(io.github.ddagunts.screencast.androidtv.IdentityStorageException("pin_storage_failed")))
        assertEquals("identity_changed", SonyTransport.safeError(SecurityException("identity_changed")))
        assertEquals("transport_unavailable", SonyTransport.safeError(io.github.ddagunts.screencast.androidtv.CommandNotSent("transport_unavailable")))
        assertEquals("connection_failed", SonyTransport.safeError(IllegalStateException("synthetic private payload")))
    }
    @Test fun wakePacketUsesSixByteNetworkAddressSixteenTimes() {
        val packet = TvController.wakePacket("02:11:22:33:44:55")
        assertEquals(102, packet.size)
        assertArrayEquals(ByteArray(6) { 0xff.toByte() }, packet.copyOfRange(0, 6))
        val mac = byteArrayOf(0x02, 0x11, 0x22, 0x33, 0x44, 0x55)
        for (index in 0 until 16) assertArrayEquals(mac, packet.copyOfRange(6 + index * 6, 12 + index * 6))
    }
    private fun command(kind: CommandKind = CommandKind.KEY, session: Long = 1) = TvCommand("a", session,
        kind, 19, null, null, "press", null, false, false, false)
    private class Port(override val id: String, var result: CommandOutcome) : CommandTransport {
        override var connectionGeneration = 1L
        val calls = mutableListOf<TvCommand>()
        override fun accepts(command: TvCommand) = true
        override suspend fun send(command: TvCommand, expectedConnection: Long): CommandOutcome { calls += command; return result }
    }
    @Test fun uncertainDeliveryNeverFallsBack() = runBlocking {
        for (delivery in listOf(Delivery.SENT, Delivery.CONFIRMED, Delivery.UNKNOWN)) {
            val first = Port("native", CommandOutcome(delivery, "native", null))
            val second = Port("sony", CommandOutcome(Delivery.SENT, "sony", null))
            val router = CapabilityRouter({ true }) { listOf(first, second) }
            assertEquals(delivery, router.execute(command()).delivery)
            assertTrue(second.calls.isEmpty())
        }
    }
    @Test fun definiteUnavailableFallsBackExactlyOnce() = runBlocking {
        val first = Port("native", CommandOutcome(Delivery.NOT_SENT, "native", "transport_unavailable"))
        val second = Port("sony", CommandOutcome(Delivery.SENT, "sony", null))
        assertEquals("sony", CapabilityRouter({ true }) { listOf(first, second) }.execute(command()).transport)
        assertEquals(1, first.calls.size); assertEquals(1, second.calls.size)
    }
    @Test fun staleContextDoesNotFallBack() = runBlocking {
        val first = Port("native", CommandOutcome(Delivery.NOT_SENT, "native", "editor_changed"))
        val second = Port("vnc", CommandOutcome(Delivery.SENT, "vnc", null))
        CapabilityRouter({ true }) { listOf(first, second) }.execute(command(CommandKind.TEXT))
        assertTrue(second.calls.isEmpty())
    }
    @Test fun releaseGoesToOriginTransportEvenWhenPreferenceChanges() = runBlocking {
        val original = Port("native", CommandOutcome(Delivery.SENT, "native", null))
        val replacement = Port("sony", CommandOutcome(Delivery.SENT, "sony", null))
        var ports = listOf(original)
        val router = CapabilityRouter({ true }) { ports }
        router.execute(command(CommandKind.KEY_DOWN))
        ports = listOf(replacement)
        router.execute(command(CommandKind.KEY_UP))
        assertEquals(listOf(CommandKind.KEY_DOWN, CommandKind.KEY_UP), original.calls.map { it.kind })
        assertTrue(replacement.calls.isEmpty())
    }
    @Test fun newTargetRejectsOldCommandAndReleasesOriginalKeys() = runBlocking {
        var session = 1L
        val original = Port("native", CommandOutcome(Delivery.SENT, "native", null))
        val router = CapabilityRouter({ it.sessionId == session }) { listOf(original) }
        router.execute(command(CommandKind.KEY_DOWN)); session = 2
        assertEquals(Delivery.NOT_SENT, router.execute(command()).delivery)
        router.releaseAll()
        assertEquals(2, original.calls.size)
        assertEquals(1L, original.calls.last().sessionId)
    }
    @Test fun uncertainDownStillRequiresRelease() = runBlocking {
        val original = Port("native", CommandOutcome(Delivery.UNKNOWN, "native", "delivery_unknown"))
        val router = CapabilityRouter({ true }) { listOf(original) }
        router.execute(command(CommandKind.KEY_DOWN)); router.releaseAll(); router.releaseAll()
        assertEquals(2, original.calls.size)
    }
    @Test fun reconnectDoesNotReceiveReleaseFromPriorSocket() = runBlocking {
        val port = Port("remote", CommandOutcome(Delivery.SENT, "remote", null))
        val router = CapabilityRouter({ true }) { listOf(port) }
        router.execute(command(CommandKind.KEY_DOWN)); port.connectionGeneration++
        assertEquals("press_expired", router.execute(command(CommandKind.KEY_UP)).errorCode)
        assertEquals(1, port.calls.size)
    }
    @Test fun duplicateDownAndUnownedReleaseCannotActuate() = runBlocking {
        val original = Port("native", CommandOutcome(Delivery.SENT, "native", null))
        val router = CapabilityRouter({ true }) { listOf(original) }
        assertEquals(Delivery.NOT_SENT, router.execute(command(CommandKind.KEY_UP)).delivery)
        router.execute(command(CommandKind.KEY_DOWN))
        assertEquals(Delivery.NOT_SENT, router.execute(command(CommandKind.KEY_DOWN)).delivery)
        assertEquals(1, original.calls.size)
    }
    @Test fun rejectsNonLocalAddressClasses() {
        for (address in listOf("127.0.0.1", "0.0.0.0", "8.8.8.8", "224.0.0.1", "::1", "::", "2001:4860:4860::8888"))
            assertFalse(address, PrivateNetwork.isLocal(InetAddress.getByName(address)))
        for (address in listOf("192.168.1.50", "10.2.3.4", "172.16.1.2", "fd12::1"))
            assertTrue(address, PrivateNetwork.isLocal(InetAddress.getByName(address)))
    }
    @Test fun rejectsURLSyntaxBeforeResolving() = runBlocking {
        for (host in listOf("https://192.168.1.4", "user@192.168.1.4", "192.168.1.4/x", "192.168.1.4?q=1", "192.168.1.4#f", " a ")) {
            try { PrivateNetwork.resolve(host); fail("URL syntax accepted") }
            catch (e: LocalRequestError) { assertEquals("invalid_address", e.code) }
        }
    }
}
