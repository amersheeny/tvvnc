package dev.tvvnc.tv_vnc.core

import io.github.ddagunts.screencast.androidtv.CommandNotSent

data class SonyVolume(val target: String, val level: Long?, val minimum: Long?,
    val maximum: Long?, val muted: Boolean?) {
    val absoluteReady: Boolean get() = target.isNotBlank() && minimum != null && maximum != null &&
        minimum >= 0 && maximum in minimum..Int.MAX_VALUE.toLong() && level != null &&
        (level in minimum..maximum || muted == true && level == 0L)
    val context: String? get() = if (absoluteReady) "sony:$target:$minimum:$maximum" else null
    fun request(level: Int): Map<String, String> {
        if (!absoluteReady) throw CommandNotSent("unsupported")
        if (level.toLong() !in minimum!!..maximum!!) throw CommandNotSent("invalid_command")
        return mapOf("target" to target, "volume" to level.toString())
    }
    companion object {
        fun select(outputs: List<SonyVolume>): SonyVolume? =
            outputs.firstOrNull { it.target == "speaker" } ?: outputs.firstOrNull()
    }
}
