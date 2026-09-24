package dev.tvvnc.tv_vnc.core

import dev.tvvnc.tv_vnc.bridge.Delivery
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive

/** Panel observations take precedence over Android's service state. Absence is
 * not evidence of either On or Standby. */
object PowerObservation {
    fun shouldWakeToggle(panel: String?, offIntent: Boolean, directToggleReady: Boolean = false,
        unresolvedWake: Boolean = false): Boolean = unresolvedWake || !directToggleReady && when (panel) {
        "on" -> false
        "standby" -> true
        else -> offIntent
    }
    fun isOn(panel: String?, androidOn: Boolean?, panelIdentified: Boolean = false): Boolean = when (panel) {
        "on" -> true
        "standby" -> false
        else -> !panelIdentified && androidOn == true
    }
    fun isStandby(panel: String?, androidOn: Boolean?, panelIdentified: Boolean = false): Boolean = when (panel) {
        "standby" -> true
        "on" -> false
        else -> !panelIdentified && androidOn == false
    }
    fun wakeMayBeInFlight(previous: Boolean, delivery: Delivery): Boolean = previous || delivery in
        setOf(Delivery.SENT, Delivery.CONFIRMED, Delivery.UNKNOWN, Delivery.QUEUED)

    fun canWakeWithToggle(wakeMayBeInFlight: Boolean, panel: String?, androidOn: Boolean?,
        panelIdentified: Boolean): Boolean = !wakeMayBeInFlight && isStandby(panel, androidOn, panelIdentified)
    suspend fun awaitOn(observe: suspend () -> Boolean) {
        while (!observe()) delay(250)
    }
    suspend fun awaitWake(job: Job?, owned: () -> Boolean, observedOn: () -> Boolean) {
        try {
            job?.join()
            if (!observedOn()) throw LocalRequestError("wake_unconfirmed")
        } finally {
            if (owned() && !currentCoroutineContext().isActive) job?.cancel()
        }
    }
}
