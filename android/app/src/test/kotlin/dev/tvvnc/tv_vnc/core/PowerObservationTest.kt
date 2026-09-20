package dev.tvvnc.tv_vnc.core

import org.junit.Assert.*
import org.junit.Test

class PowerObservationTest {
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
}
