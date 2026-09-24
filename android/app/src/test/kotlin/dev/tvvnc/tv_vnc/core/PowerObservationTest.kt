package dev.tvvnc.tv_vnc.core

import org.junit.Assert.*
import org.junit.Test
import kotlinx.coroutines.*

class PowerObservationTest {
    @Test fun aReadyNativeRemoteKeepsThePhysicalPowerToggleInEveryPanelState() {
        for (panel in listOf("on", "standby", null)) {
            for (offIntent in listOf(false, true)) {
                assertFalse(PowerObservation.shouldWakeToggle(panel, offIntent, directToggleReady = true))
                assertEquals(PowerObservation.shouldWakeToggle(panel, offIntent),
                    PowerObservation.shouldWakeToggle(panel, offIntent, directToggleReady = false))
            }
        }
    }
    @Test fun powerToggleWakesAnObservedStandbyPanelWithoutAStoredOffIntent() {
        assertTrue(PowerObservation.shouldWakeToggle("standby", false))
        assertTrue(PowerObservation.shouldWakeToggle("standby", true))
    }
    @Test fun restoredOffIntentCanWakeBeforeTheMethodCatalogIsAvailable() {
        assertTrue(PowerObservation.shouldWakeToggle(null, true))
        assertFalse(PowerObservation.shouldWakeToggle(null, false))
    }
    @Test fun aFreshOnObservationTakesPrecedenceOverAnOldOffIntent() {
        assertFalse(PowerObservation.shouldWakeToggle("on", true))
        assertFalse(PowerObservation.shouldWakeToggle("on", false))
    }
    @Test fun unknownIsNotOnOrStandby() {
        assertFalse(PowerObservation.isOn(null, null))
        assertFalse(PowerObservation.isStandby(null, null))
    }
    @Test fun panelOverridesConflictingAndroidState() {
        assertFalse(PowerObservation.isOn("standby", true))
        assertFalse(PowerObservation.isStandby("on", false))
        assertTrue(PowerObservation.isOn("on", false))
        assertTrue(PowerObservation.isStandby("standby", true))
    }
    @Test fun nativeObservationSuppliesMissingPanelState() {
        assertTrue(PowerObservation.isOn(null, true))
        assertFalse(PowerObservation.isOn(null, false))
        assertTrue(PowerObservation.isStandby(null, false))
    }
    @Test fun identifiedPanelNeverUsesAndroidInteractivityAsPowerProof() {
        assertFalse(PowerObservation.isOn(null, true, panelIdentified = true))
        assertTrue(PowerObservation.isOn("on", false, panelIdentified = true))
        assertFalse(PowerObservation.isOn("standby", true, panelIdentified = true))
    }
    @Test fun aShortPowerWaitTimesOutWithoutAdvancingTheMacro() = runBlocking {
        var checks = 0
        var nextStep = false
        try {
            withTimeout(50) {
                PowerObservation.awaitOn { checks++; PowerObservation.isOn(null, true, panelIdentified = true) }
                nextStep = true
            }
            fail("unknown panel completed the wait")
        } catch (_: TimeoutCancellationException) { }
        assertTrue(checks > 0)
        assertFalse(nextStep)
    }
    @Test fun timedOutMacroCancelsItsWakeButNotAManualWake() = runBlocking {
        for (owned in listOf(true, false)) {
            val wake = launch { awaitCancellation() }
            try {
                try { withTimeout(50) { PowerObservation.awaitWake(wake, { owned }) { false } }; fail("wake completed") }
                catch (_: TimeoutCancellationException) { }
                assertEquals(!owned, wake.isActive)
            } finally { wake.cancelAndJoin() }
        }
    }
    @Test fun manualOwnershipTakenDuringWakeIsNotCancelledByMacroTimeout() = runBlocking {
        var owned = true
        val wake = launch { awaitCancellation() }
        val waiting = async {
            try { withTimeout(100) { PowerObservation.awaitWake(wake, { owned }) { false } }; fail("wake completed") }
            catch (_: TimeoutCancellationException) { }
        }
        yield()
        owned = false
        try { waiting.await(); assertTrue(wake.isActive) }
        finally { wake.cancelAndJoin() }
    }
}
