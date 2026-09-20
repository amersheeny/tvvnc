package dev.tvvnc.tv_vnc.core

import dev.tvvnc.tv_vnc.bridge.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

interface CommandTransport {
    val id: String
    val connectionGeneration: Long get() = 0
    fun accepts(command: TvCommand): Boolean
    suspend fun send(command: TvCommand, expectedConnection: Long = connectionGeneration): CommandOutcome
}

/** All routing lives below the UI. Delivery certainty and input context are
 * orthogonal: a stale command is never retried, even if nothing was sent. */
class CapabilityRouter(private val valid: (TvCommand) -> Boolean,
    private val transports: (TvCommand) -> List<CommandTransport>) {
    private val lock = Mutex()
    private data class Press(val transport: CommandTransport, val command: TvCommand, val generation: Long)
    private val held = mutableMapOf<String, Press>()

    suspend fun execute(command: TvCommand): CommandOutcome {
        val candidates = transports(command).map { it to it.connectionGeneration }
        return lock.withLock {
        if (!valid(command)) return@withLock CommandOutcome(Delivery.NOT_SENT, null, "stale_session")
        if (command.kind == CommandKind.KEY_UP) {
            val press = held.remove(command.pressId) ?: return@withLock CommandOutcome(Delivery.NOT_SENT, null, "press_missing")
            if (press.transport.connectionGeneration != press.generation)
                return@withLock CommandOutcome(Delivery.NOT_SENT, press.transport.id, "press_expired")
            return@withLock press.transport.send(press.command.copy(kind = CommandKind.KEY_UP), press.generation)
        }
        if (command.kind == CommandKind.KEY_DOWN && (command.pressId.isNullOrBlank() || held.containsKey(command.pressId)))
            return@withLock CommandOutcome(Delivery.NOT_SENT, null, "invalid_press")
        // No currently usable adapter is not proof that the TV lacks support.
        var last = CommandOutcome(Delivery.NOT_SENT, null, "transport_unavailable")
        for ((transport, generation) in candidates) {
            if (!valid(command)) return@withLock CommandOutcome(Delivery.NOT_SENT, null, "stale_session")
            if (transport.connectionGeneration != generation)
                return@withLock CommandOutcome(Delivery.NOT_SENT, transport.id, "stale_session")
            if (!transport.accepts(command)) continue
            last = transport.send(command, generation)
            if (command.kind == CommandKind.KEY_DOWN && last.delivery in setOf(Delivery.SENT, Delivery.CONFIRMED, Delivery.UNKNOWN))
                held[command.pressId!!] = Press(transport, command, generation)
            if (!mayFallback(last)) return@withLock last
        }
        last
        }
    }

    suspend fun releaseAll(): List<CommandOutcome> = lock.withLock {
        val presses = held.values.toList(); held.clear()
        presses.map { press -> if (press.transport.connectionGeneration == press.generation)
            press.transport.send(press.command.copy(kind = CommandKind.KEY_UP), press.generation)
            else CommandOutcome(Delivery.NOT_SENT, press.transport.id, "press_expired") }
    }

    companion object {
        fun liveRemoteAvailability(connected: Boolean, reported: Availability): Availability =
            if (connected) Availability.READY else reported.takeUnless { it == Availability.READY } ?: Availability.UNAVAILABLE
        /** A dead connection does not establish lack of device support. */
        fun bestAvailability(candidates: List<Availability>): Availability = listOf(
            Availability.READY, Availability.ADVERTISED, Availability.NEEDS_SETUP,
            Availability.PERMISSION_REQUIRED, Availability.UNKNOWN, Availability.UNAVAILABLE,
            Availability.UNSUPPORTED,
        ).first { it in candidates }
        fun mayFallback(result: CommandOutcome) =
            result.delivery in setOf(Delivery.NOT_SENT, Delivery.REJECTED) &&
                result.errorCode in setOf("unsupported", "transport_unavailable", "remote_disconnected", "authentication_required", "pairing_required")
    }
}

data class SemanticKey(val id: String, val code: Int, val sony: List<String>, val rfb: Int? = null)
object RemoteKeys {
    val all = listOf(
        SemanticKey("up", 19, listOf("Up"), 0xff52), SemanticKey("down", 20, listOf("Down"), 0xff54),
        SemanticKey("left", 21, listOf("Left"), 0xff51), SemanticKey("right", 22, listOf("Right"), 0xff53),
        SemanticKey("ok", 23, listOf("Confirm"), 0xff0d), SemanticKey("home", 3, listOf("Home")),
        SemanticKey("back", 4, listOf("Return")), SemanticKey("options", 82, listOf("ActionMenu", "Options")),
        SemanticKey("input", 178, listOf("Input")), SemanticKey("guide", 172, listOf("GGuide", "Guide")),
        SemanticKey("info", 165, listOf("Display", "Info")), SemanticKey("volumeUp", 24, listOf("VolumeUp")),
        SemanticKey("volumeDown", 25, listOf("VolumeDown")), SemanticKey("mute", 164, listOf("Mute")),
        SemanticKey("channelUp", 166, listOf("ChannelUp")), SemanticKey("channelDown", 167, listOf("ChannelDown")),
        SemanticKey("rewind", 89, listOf("Rewind")), SemanticKey("playPause", 85, listOf("PlayPause")),
        SemanticKey("play", 126, listOf("Play")), SemanticKey("pause", 127, listOf("Pause")),
        SemanticKey("fastForward", 90, listOf("Forward")), SemanticKey("previous", 88, listOf("Prev", "Previous")),
        SemanticKey("stop", 86, listOf("Stop")), SemanticKey("next", 87, listOf("Next")),
        SemanticKey("enter", 66, listOf(), 0xff0d), SemanticKey("backspace", 67, listOf(), 0xff08),
        SemanticKey("delete", 112, listOf(), 0xffff), SemanticKey("search", 84, listOf()),
    ) + (0..9).map { SemanticKey("number$it", it + 7, listOf("Num$it"), '0'.code + it) }
    fun forCode(code: Long?) = all.firstOrNull { it.code.toLong() == code }
}
