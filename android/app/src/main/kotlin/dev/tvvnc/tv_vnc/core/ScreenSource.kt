package dev.tvvnc.tv_vnc.core

import dev.tvvnc.tv_vnc.bridge.ScreenInfo

/** Viewing is independent of control. A future local HDMI feed can implement
 * this without taking ownership of Android/Sony commands or connection intent. */
interface ScreenSource {
    val state: ScreenInfo
    suspend fun show(): ScreenInfo
    suspend fun hide()
    suspend fun screenshot(): String
    suspend fun refresh(): Int
    fun invalidate()
    suspend fun close()
}
