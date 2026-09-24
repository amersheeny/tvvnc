package dev.tvvnc.tv_vnc.core

import dev.tvvnc.tv_vnc.bridge.*
import org.junit.Assert.*
import org.junit.Test

class SonyInputCatalogTest {
    @Test fun fallbackUsesReportedContentForSelectionAndMacroAcknowledgement() {
        assertTrue(SonyTransport.inputMatches("command:Hdmi2", "extInput:hdmi?port=2"))
        assertTrue(SonyTransport.inputMatches("command:Hdmi2", "extInput:hdmi?label=player&port=2"))
        assertFalse(SonyTransport.inputMatches("command:Hdmi2", "extInput:hdmi?port=20"))
        assertFalse(SonyTransport.inputMatches("command:Hdmi2", null))
        assertTrue(SonyTransport.inputMatches("command:Tv", "tv:dvbt?trip=1"))
    }
    @Test fun fallbackContainsOnlyReportedDiscreteSafeInputs() {
        val buttons = listOf("Hdmi2", "Hdmi4", "Tv", "Input", "FactoryReset", "Hdmi2").map {
            TvButton("sony:$it", it, null, "AAAA", false, false, Availability.ADVERTISED)
        }
        val inputs = SonyTransport.reportedInputFallback(buttons)
        assertEquals(listOf("command:Hdmi2", "command:Hdmi4", "command:Tv"), inputs.map { it.uri })
        assertFalse(inputs.any { it.connected || it.selected })
        assertTrue(SonyTransport.reportedInputFallback(emptyList()).isEmpty())
    }
}
