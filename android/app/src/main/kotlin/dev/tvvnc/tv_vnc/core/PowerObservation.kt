package dev.tvvnc.tv_vnc.core

/** Panel observations take precedence over Android's service state. Absence is
 * not evidence of either On or Standby. */
object PowerObservation {
    fun isOn(panel: String?, androidOn: Boolean?): Boolean = when (panel) {
        "on" -> true
        "standby" -> false
        else -> androidOn == true
    }
    fun isStandby(panel: String?, androidOn: Boolean?): Boolean = when (panel) {
        "standby" -> true
        "on" -> false
        else -> androidOn == false
    }
}
