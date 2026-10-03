package dev.tvvnc.tv_vnc.core

import io.github.ddagunts.screencast.androidtv.CommandNotSent
import org.junit.Assert.*
import org.junit.Test

class SonyVolumeTest {
    @Test fun namedOutputAndNonzeroMinimumSurviveSelectionAndRequests() {
        val headphone = SonyVolume("headphone", 15, 10, 30, false)
        val selected = SonyVolume.select(listOf(headphone))!!
        assertTrue(selected.absoluteReady)
        assertEquals(mapOf("target" to "headphone", "volume" to "20"), selected.request(20))
        assertEquals("sony:headphone:10:30", selected.context)
        try { selected.request(9); fail("minimum ignored") }
        catch (e: CommandNotSent) { assertEquals("invalid_command", e.reason) }
    }
    @Test fun speakerPreferenceDoesNotDiscardTheChosenTargetsIdentity() {
        val headphone = SonyVolume("headphone", 15, 10, 30, false)
        val speaker = SonyVolume("speaker", 20, 0, 100, false)
        assertEquals(speaker, SonyVolume.select(listOf(headphone, speaker)))
        assertEquals("speaker", SonyVolume.select(listOf(headphone, speaker))!!.request(25)["target"])
        assertNotEquals(headphone.context, speaker.context)
        assertNotEquals(headphone.context, headphone.copy(maximum = 25).context)
    }
    @Test fun absentRangeNeverBecomesZeroToOneHundred() {
        val observed = SonyVolume("speaker", 20, null, null, true)
        assertEquals(true, observed.muted)
        for (value in listOf(observed, observed.copy(minimum = 0), observed.copy(maximum = 100),
            observed.copy(minimum = 50, maximum = 20), observed.copy(target = "", minimum = 0, maximum = 100))) {
            assertFalse(value.absoluteReady)
            assertNull(value.context)
            try { value.request(20); fail("unobserved range accepted") }
            catch (e: CommandNotSent) { assertEquals("unsupported", e.reason) }
        }
    }
}
