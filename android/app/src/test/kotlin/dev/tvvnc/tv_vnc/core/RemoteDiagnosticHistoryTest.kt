package dev.tvvnc.tv_vnc.core

import io.github.ddagunts.screencast.androidtv.logging.RemoteDiagnostic
import org.junit.Assert.*
import org.junit.Test

class RemoteDiagnosticHistoryTest {
    @Test fun boundedRecentHistoryDoesNotEraseEarlierObservedKinds() {
        val history = RemoteDiagnosticHistory()
        history.onEvent(RemoteDiagnostic.IME_APP_ONLY)
        repeat(40) {
            history.onEvent(if (it % 2 == 0) RemoteDiagnostic.IME_FIELD_WITH_TEXT else RemoteDiagnostic.IME_VISIBILITY_UPDATED)
        }
        val (recent, seen) = history.snapshot()
        assertEquals(16, recent.size)
        assertFalse(recent.contains("IME_APP_ONLY"))
        assertTrue(seen.contains("IME_APP_ONLY"))
        assertEquals(3, seen.size)
    }

    @Test fun repeatedKindsAreCoalescedWithoutPayloads() {
        val history = RemoteDiagnosticHistory()
        repeat(100) { history.onEvent(RemoteDiagnostic.IME_FIELD_WITH_TEXT) }
        assertEquals(listOf("IME_FIELD_WITH_TEXT") to listOf("IME_FIELD_WITH_TEXT"), history.snapshot())
    }
}
