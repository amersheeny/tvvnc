package dev.tvvnc.tv_vnc.core

import io.github.ddagunts.screencast.androidtv.logging.DiagnosticSink
import io.github.ddagunts.screencast.androidtv.logging.RemoteDiagnostic
import java.util.EnumSet

/** Bounded, payload-free observations for one control session, including its
 * reconnects. Recent ordering and ever-seen kinds answer different questions. */
class RemoteDiagnosticHistory : DiagnosticSink {
    private val recent = ArrayDeque<RemoteDiagnostic>()
    private val seen = EnumSet.noneOf(RemoteDiagnostic::class.java)

    @Synchronized override fun onEvent(event: RemoteDiagnostic) {
        seen.add(event)
        if (recent.lastOrNull() != event) {
            if (recent.size == 16) recent.removeFirst()
            recent.addLast(event)
        }
    }

    @Synchronized fun snapshot(): Pair<List<String>, List<String>> =
        recent.map { it.name } to seen.map { it.name }
}
