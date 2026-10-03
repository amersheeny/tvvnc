package dev.tvvnc.tv_vnc.core

import dev.tvvnc.tv_vnc.bridge.Availability
import kotlinx.coroutines.*
import org.junit.Assert.*
import org.junit.Test
import java.io.IOException
import javax.net.ssl.SSLHandshakeException

class PairingAndStatusTest {
    @Test fun observedSonyAuthenticationFailureOutranksReadablePower() {
        val state = SonySnapshot(available = true, power = "on", audio = SonyVolume("speaker", 22, null, null, null),
            errors = mapOf("appControl.getApplicationList" to "authentication_required"))
        assertEquals(Availability.NEEDS_SETUP, state.availability(true))
        assertEquals("on", state.power)
        assertEquals(22L, state.volume)
        assertEquals(Availability.READY, state.copy(errors = emptyMap()).availability(true))
        assertEquals(Availability.UNKNOWN, SonySnapshot().availability(false))
        assertEquals(Availability.UNAVAILABLE, SonySnapshot().availability(true))
    }

    @Test fun handshakeAndNegotiationErrorsNeverBlameAnEnteredCode() {
        assertEquals("secure_connection_failed", TvController.safeError(SSLHandshakeException("synthetic private detail")))
        assertEquals("pairing_unavailable", TvController.safeError(IOException("pairing_unavailable")))
        assertEquals("pairing_protocol_error", TvController.safeError(IOException("pairing_protocol_error")))
        assertEquals("pairing_rejected", TvController.safeError(IOException("pairing_rejected")))
        assertEquals("pairing_rejected", TvController.safeError(IllegalArgumentException("pairing_rejected")))
        assertEquals("connection_failed", TvController.safeError(IOException("unapproved private message")))
        assertEquals("identity_changed", TvController.safeError(SecurityException("identity_changed")))
        val certificateFailure = SSLHandshakeException("certificate").apply { initCause(java.security.cert.CertificateException()) }
        assertEquals("identity_changed", TvController.safeError(certificateFailure))
    }

    @Test fun codeEntryExpiryIsNotUserCancellation() = runBlocking {
        try {
            TvController.awaitPairingCode(CompletableDeferred(), 1)
            fail("expired code request completed")
        } catch (expected: LocalRequestError) {
            assertEquals("pairing_timeout", expected.code)
        }
        val pending = CompletableDeferred<String>()
        val waiting = async(start = CoroutineStart.UNDISPATCHED) {
            TvController.awaitPairingCode(pending, 10_000)
        }
        waiting.cancel()
        try { waiting.await(); fail("cancellation became a value") }
        catch (_: CancellationException) { }
        assertEquals("ABCDEF", TvController.awaitPairingCode(CompletableDeferred("ABCDEF")))
    }
}
