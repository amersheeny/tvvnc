package dev.tvvnc.tv_vnc.core

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.SystemClock
import dev.tvvnc.tv_vnc.bridge.*
import io.flutter.view.TextureRegistry
import io.github.ddagunts.screencast.androidtv.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import org.json.JSONObject
import java.net.*
import java.util.concurrent.atomic.AtomicLong

/** Foreground, per-target ownership. Each transport recovers independently; no
 * connector owns wake, UI lifetime, or another connector's retry policy. */
class TvController(private val context: Context, private val textures: TextureRegistry,
    private val permissions: Permissions, private val flutter: TvFlutterApi) : TvHostApi {
    private val root = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val switchLock = Mutex()
    private val store = ProfileStore(context)
    private val epochs = AtomicLong()
    private var selected: Session? = null
    private var resumeId: String? = null
    private var foreground = true
    private val connectivity = context.getSystemService(ConnectivityManager::class.java)
    private var network: Network? = connectivity.activeNetwork
    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(current: Network) { root.launch { changedNetwork(current) } }
        override fun onLost(current: Network) { root.launch { if (network == current) changedNetwork(null) } }
    }
    init { connectivity.registerDefaultNetworkCallback(networkCallback) }

    override suspend fun profiles() = withContext(Dispatchers.IO) { store.list() }
    override suspend fun saveProfile(profile: TvProfile, credentials: TvCredentials?): TvProfile {
        // Saving a layout or an offline TV must not require a working network.
        // Every actual connector resolves and confines its numeric endpoint.
        require(profile.host.none { it.isWhitespace() || it in "/@?#" }) { "invalid_address" }
        val saved = withContext(Dispatchers.IO) { store.saveUser(profile, credentials) }
        val active = selected
        if (active?.profile?.id == saved.id) {
            val endpointChanged = active.profile.host != saved.host || active.profile.vncPort != saved.vncPort ||
                active.profile.remotePort != saved.remotePort || active.profile.pairingPort != saved.pairingPort || credentials != null
            if (endpointChanged) connect(saved.id) else { active.profile = saved; active.publish() }
        }
        return saved
    }
    override suspend fun forget(deviceId: String) {
        selected?.takeIf { it.profile.id == deviceId }?.let { disconnect(deviceId, it.id) }
        withContext(Dispatchers.IO) { store.forget(deviceId) }
        if (resumeId == deviceId) resumeId = null
    }
    override suspend fun requestNetworkPermission() = permissions.network()
    override suspend fun networkPermissionAllowed() = permissions.networkAllowed()
    override suspend fun openSettings() = withContext(Dispatchers.Main) { permissions.openSettings() }
    override suspend fun discover(): List<DiscoveredTv> {
        if (!permissions.networkAllowed()) throw LocalRequestError("network_permission")
        return try { LanDiscovery(context).scan() } catch (e: Exception) {
            if (e is CancellationException) throw e
            if (safeError(e) == "network_permission") { permissions.noteNetworkDenial(); throw LocalRequestError("network_permission") }
            throw e
        }
    }
    override suspend fun connect(deviceId: String): SessionSnapshot = switchLock.withLock {
        check(foreground) { "background" }
        selected?.close(); selected = null
        val profile = withContext(Dispatchers.IO) { store.read(deviceId) }
        withContext(Dispatchers.IO) { store.setConnectIntent(deviceId, true) }
        resumeId = deviceId
        val session = Session(profile, epochs.incrementAndGet())
        selected = session
        session.start()
        session.snapshot()
    }
    override suspend fun disconnect(deviceId: String, sessionId: Long) = switchLock.withLock {
        val session = target(deviceId, sessionId)
        withContext(Dispatchers.IO) { store.setConnectIntent(deviceId, false) }
        session.close(); session.stage = "disconnected"; session.publish()
        resumeId = null
    }
    private fun target(deviceId: String, sessionId: Long): Session = selected?.takeIf {
        it.profile.id == deviceId && it.id == sessionId
    } ?: throw LocalRequestError("stale_session")
    override suspend fun pairRemote(deviceId: String) {
        val session = selected?.takeIf { it.profile.id == deviceId && !it.closed } ?: run {
            connect(deviceId); selected!!
        }
        session.pair()
    }
    override suspend fun submitPairingCode(deviceId: String, sessionId: Long, code: String) {
        val session = target(deviceId, sessionId)
        require(code.matches(Regex("[0-9a-fA-F]{6}"))) { "pairing_rejected" }
        session.pairCode?.complete(code) ?: throw LocalRequestError("pairing_cancelled")
    }
    override suspend fun cancelPairing(deviceId: String, sessionId: Long) { target(deviceId, sessionId).cancelPair() }
    override suspend fun registerSony(deviceId: String, sessionId: Long, pin: String?): Boolean {
        val session = target(deviceId, sessionId)
        try {
            if (session.closed || !foreground) throw LocalRequestError("not_connected")
            val revision = withContext(Dispatchers.IO) { store.sonyAuthRevision(deviceId) }
            val cookie = session.sony.register(deviceId, pin)
            if (selected !== session || session.closed || !foreground) throw LocalRequestError("stale_session")
            withContext(Dispatchers.IO) { store.saveSonyCookie(deviceId, revision, cookie) }
            session.refreshSony(true)
            return true
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            if (pin != null || safeError(e) != "authentication_required") throw e
            // The initial unauthenticated registration intentionally asks the TV
            // to show a PIN. Only this explicit API, never discovery, does that.
            return false
        }
    }
    override suspend fun applicationIcon(deviceId: String, sessionId: Long, appId: String): ByteArray? {
        val session = target(deviceId, sessionId)
        return session.sony.icon(appId)
    }
    override suspend fun execute(command: TvCommand): CommandOutcome {
        val session = target(command.deviceId, command.sessionId)
        session.cancelMacro()
        return session.execute(command)
    }
    override suspend fun startScreen(deviceId: String, sessionId: Long): ScreenInfo {
        val session = target(deviceId, sessionId)
        session.viewerWanted = true
        session.vnc?.show() ?: session.ensureVnc()
        return session.vnc?.state ?: blankScreen()
    }
    override suspend fun stopScreen(deviceId: String, sessionId: Long) {
        val session = target(deviceId, sessionId)
        session.viewerWanted = false; session.vnc?.hide()
        session.publish()
    }
    override suspend fun pointer(x: Long, y: Long, buttons: Long, generation: Long) {
        require(buttons in 0..255)
        val session = selected ?: return
        session.cancelMacro()
        val vnc = session.vnc ?: return
        if (session.closed || generation != vnc.state.generation) return
        vnc.pointer(x.toInt(), y.toInt(), buttons.toInt(), generation)
    }
    override suspend fun screenDetail(deviceId: String, sessionId: Long, fullResolution: Boolean) {
        target(deviceId, sessionId).vnc?.detail(fullResolution)
    }
    override suspend fun screenshot(deviceId: String, sessionId: Long) =
        target(deviceId, sessionId).vnc?.screenshot() ?: throw LocalRequestError("screen_unavailable")
    override suspend fun startVoice(deviceId: String, sessionId: Long) {
        val session = target(deviceId, sessionId)
        if (session.closed || !foreground) throw LocalRequestError("not_connected")
        if (session.identity.pin() == null) throw LocalRequestError("pairing_required")
        session.cancelMacro(); session.voice.start(session.remote)
    }
    override suspend fun stopVoice(deviceId: String, sessionId: Long) { target(deviceId, sessionId).voice.stop() }
    override suspend fun refresh(deviceId: String, sessionId: Long): SessionSnapshot {
        val session = target(deviceId, sessionId)
        session.refreshSony(true); session.publish()
        return session.snapshot()
    }
    override suspend fun reconnectTransport(deviceId: String, sessionId: Long, transport: String) {
        val session = target(deviceId, sessionId)
        if (session.closed) { connect(deviceId); return }
        when (transport) {
            "sony" -> session.refreshSony(true)
            "remote" -> { session.voice.stop(); session.router.releaseAll(); session.remote.disconnect(); session.connectRemote() }
            "vnc" -> { session.router.releaseAll(); session.vnc?.close(); session.vnc = null; session.ensureVnc() }
            else -> throw LocalRequestError("unsupported")
        }
    }
    override suspend fun diagnosticReport(deviceId: String, sessionId: Long): String {
        val session = target(deviceId, sessionId)
        val profile = session.profile
        val ip = PrivateNetwork.resolve(profile.host)
        val probes = coroutineScope {
            listOf(80, profile.vncPort.toInt(), profile.remotePort.toInt(), profile.pairingPort.toInt()).distinct().map { port ->
                async(Dispatchers.IO) {
                    val start = SystemClock.elapsedRealtime()
                    try {
                        Socket().use { it.connect(InetSocketAddress(ip, port), 1500) }
                        JSONObject().put("port", port).put("reachable", true).put("latencyMs", SystemClock.elapsedRealtime() - start)
                    } catch (e: Exception) { JSONObject().put("port", port).put("reachable", false).put("error", safeError(e)) }
                }
            }.awaitAll()
        }
        val snapshot = session.snapshot()
        // Deliberate allowlist: never serialize profiles, commands, editor text,
        // cookies, certificates, keys, credentials or captured pixels.
        return JSONObject().put("format", 1).put("time", System.currentTimeMillis())
            .put("ip", ip).put("mac", snapshot.mac).put("model", snapshot.model)
            .put("software", snapshot.firmware).put("remoteService", snapshot.remoteVersion)
            .put("power", snapshot.power).put("screenConnected", snapshot.screen.connected)
            .put("lastError", snapshot.errorCode)
            .put("rfbProtocol", snapshot.screen.protocolVersion).put("rfbSecurityType", snapshot.screen.securityType)
            .put("rfbDesktopName", snapshot.screen.desktopName).put("rfbExtendedClipboard", snapshot.screen.extendedClipboard)
            .put("networkPermission", permissions.networkAllowed()).put("ports", JSONArray(probes))
            .put("remoteEvents", JSONArray(synchronized(session.remoteEvents) { session.remoteEvents.toList() }))
            .put("lastNavigation", session.lastNavigation?.let { (code, outcome) ->
                JSONObject().put("androidCode", code).put("transport", outcome.transport)
                    .put("delivery", outcome.delivery.name).put("error", outcome.errorCode)
            })
            .put("transports", JSONArray(snapshot.transports.map { JSONObject().put("id", it.id).put("state", it.state.name)
                .put("error", it.errorCode).put("observedAt", it.observedAt) }))
            .put("capabilities", JSONArray(snapshot.capabilities.map { JSONObject().put("id", it.id)
                .put("state", it.state.name).put("transport", it.transport).put("observedAt", it.observedAt) }))
            .put("sonyErrors", JSONObject(session.sony.state.errors)).toString(2)
    }
    override suspend fun runMacro(deviceId: String, sessionId: Long, macroId: String) {
        target(deviceId, sessionId).runMacro(macroId)
    }
    override suspend fun stopMacro(deviceId: String, sessionId: Long) { target(deviceId, sessionId).cancelMacro() }

    fun suspendInput() {
        selected?.voice?.stop(discardAudio = true)
        val origin = selected
        root.launch { origin?.router?.releaseAll(); origin?.vnc?.invalidate() }
    }
    fun background() {
        foreground = false
        root.launch { switchLock.withLock { selected?.close(); selected?.publish() } }
    }
    fun foreground() {
        val returning = !foreground; foreground = true
        if (returning) root.launch {
            val id = resumeId
            if (id != null && store.connectIntent(id)) connect(id)
        }
    }
    private suspend fun changedNetwork(current: Network?) {
        if (network == current) return
        network = current
        val prior = selected ?: return
        prior.error = "network_changed"
        if (foreground && store.connectIntent(prior.profile.id)) {
            val next = connect(prior.profile.id)
            selected?.error = "network_changed"; selected?.publish()
        } else { prior.close(); prior.publish() }
    }
    fun dispose() {
        connectivity.unregisterNetworkCallback(networkCallback)
        root.launch { selected?.close(); root.cancel() }
    }

    private inner class Session(var profile: TvProfile, val id: Long) {
        private val snapshotSequence = AtomicLong()
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        val identity = KeystoreIdentity(context, profile.id)
        val remoteEvents = ArrayDeque<String>()
        private val diagnostics = io.github.ddagunts.screencast.androidtv.logging.DiagnosticSink { event ->
            synchronized(remoteEvents) {
                if (remoteEvents.size >= 16) remoteEvents.removeFirst()
                remoteEvents.addLast(event.name)
            }
        }
        val remote = NativeRemoteSession(identity, diagnostics)
        val sony = SonyTransport(profile.host, psk = { store.secrets.get("${profile.id}:sony") },
            cookie = { store.secrets.get("${profile.id}:sonyCookie") })
        val pairing = NativePairing(identity, diagnostics)
        val sonyLock = Mutex()
        val remoteLock = Mutex()
        val vncLock = Mutex()
        var vnc: VncBridge? = null
        var closed = false
        var viewerWanted = true
        var stage = "connecting"
        var error: String? = null
        // Only OK/Back, never characters, text, clipboard data, or directional
        // sequences that could reconstruct entry on an on-screen keyboard.
        var lastNavigation: Pair<Long, CommandOutcome>? = null
        var voiceState = "idle"
        var pairState = "idle"
        var pairCode: CompletableDeferred<String>? = null
        var pairJob: Job? = null
        private var remoteLoop: Job? = null
        private var vncLoop: Job? = null
        var macro: Job? = null
        var macroId: String? = null
        var macroStep: Long? = null
        var waking: Job? = null
        private var wakeOwnerMacro: String? = null
        private var sonyAt = 0L
        private var remoteAt = 0L
        private var remoteStatus = if (profile.paired) Availability.UNKNOWN else Availability.NEEDS_SETUP
        private var remoteError: String? = null
        private var off = store.powerOffIntent(profile.id)
        private var powerIntentEpoch = 0L
        val voice = VoiceCapture(permissions) { state, failure -> scope.launch {
            voiceState = state; if (failure != null) error = failure; publish()
        } }
        val router = CapabilityRouter({ command -> !closed && selected === this && foreground &&
            permissions.networkAllowed() && command.deviceId == profile.id && command.sessionId == id },
            { command -> if (command.kind in setOf(CommandKind.SONY, CommandKind.POWER_ON, CommandKind.POWER_OFF, CommandKind.POWER_TOGGLE) ||
                command.kind == CommandKind.KEY && command.code in setOf(82L, 178L, 172L, 165L, 166L, 167L))
                listOf(sonyPort, remotePort, vncPort) else listOf(remotePort, sonyPort, vncPort) })

        fun start() {
            if (!permissions.networkAllowed()) { stage = "permissionRequired"; error = "network_permission"; publish(); return }
            scope.launch {
                remote.state.collectLatest { state ->
                    remoteAt = System.currentTimeMillis()
                    if (state.connected) { remoteStatus = Availability.READY; remoteError = state.error; if (state.error != null) error = state.error }
                    else if (state.error != null) { remoteStatus = Availability.UNAVAILABLE; remoteError = state.error; voice.stop() }
                    publish()
                }
            }
            scope.launch {
                refreshSony(true)
                while (isActive) { delay(if (off) 10_000 else 5000); refreshSony(false) }
            }
            remoteLoop = scope.launch {
                var backoff = 1000L
                var unpairedProbed = false
                while (isActive) {
                    if (permissions.networkAllowed() && !off && identity.pin() == null && !unpairedProbed) {
                        unpairedProbed = true
                        try {
                            val ip = PrivateNetwork.resolve(profile.host)
                            withContext(Dispatchers.IO) { Socket().use { it.connect(InetSocketAddress(ip, profile.remotePort.toInt()), 1500) } }
                            remoteStatus = Availability.NEEDS_SETUP; remoteError = "pairing_required"
                        } catch (e: Exception) {
                            if (e is CancellationException) throw e
                            remoteStatus = Availability.UNAVAILABLE; remoteError = safeError(e)
                        }
                        remoteAt = System.currentTimeMillis(); publish()
                    }
                    if (permissions.networkAllowed() && !off && identity.pin() != null && !remote.state.value.connected && pairJob?.isActive != true) connectRemote()
                    if (remote.state.value.connected) backoff = 1000 else backoff = (backoff * 2).coerceAtMost(30_000)
                    delay(backoff)
                }
            }
            vncLoop = scope.launch {
                var backoff = 1000L
                while (isActive) {
                    if (permissions.networkAllowed() && !off && vnc?.state?.connected != true && vnc?.state?.errorCode != "authentication_required") ensureVnc()
                    if (vnc?.state?.connected == true) backoff = 1000 else backoff = (backoff * 2).coerceAtMost(30_000)
                    delay(backoff)
                }
            }
            publish()
        }
        suspend fun refreshSony(detect: Boolean, powerOnly: Boolean = off) = sonyLock.withLock {
            if (closed || !permissions.networkAllowed()) return@withLock
            try {
                if (detect && !off) sony.discover() else sony.refresh(false, powerOnly = powerOnly)
                if (profile.mac.isNullOrBlank() && !sony.state.mac.isNullOrBlank())
                    profile = store.update(profile.id) { it.copy(mac = sony.state.mac) }
                sonyAt = System.currentTimeMillis()
            } catch (e: Exception) { if (e is CancellationException) throw e; error = safeError(e) }
            if (off) stage = "standby" else if (sony.state.power == "on" || remote.state.value.connected || vnc?.state?.connected == true)
                stage = "connected"
            publish()
        }
        suspend fun connectRemote(allowPairOwner: Boolean = false) = remoteLock.withLock {
            if (closed || off || (pairJob?.isActive == true && !allowPairOwner) || identity.pin() == null || remote.state.value.connected) return@withLock
            if (remoteError == "identity_changed") return@withLock
            try {
                remoteStatus = Availability.ADVERTISED; publish()
                val host = PrivateNetwork.resolve(profile.host)
                if (closed || off) return@withLock
                remote.connect(host, profile.remotePort.toInt())
                remoteStatus = Availability.READY; remoteError = null
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                remoteStatus = Availability.UNAVAILABLE; remoteError = safeError(e)
            }
            remoteAt = System.currentTimeMillis(); publish()
        }
        suspend fun ensureVnc() = vncLock.withLock {
            if (closed || off) return@withLock
            if (vnc?.state?.connected == true || (vnc != null && vnc?.state?.errorCode == null)) return@withLock
            vnc?.close()
            val bridge = VncBridge(context, textures) { frame ->
                if (!closed && selected === this) scope.launch {
                    try {
                        flutter.screenChanged(profile.id, id, frame.copy(hidden = !viewerWanted))
                        if (!frame.connected || frame.errorCode != null) publish()
                    } catch (e: Exception) {
                        if (e is CancellationException) throw e
                        android.util.Log.w("TVConsole", "flutter_screen_unavailable")
                        close()
                    }
                }
            }
            vnc = bridge
            try {
                bridge.start(profile.host, profile.vncPort.toInt(), store.secrets.get("${profile.id}:vnc").orEmpty())
                if (!viewerWanted) bridge.hide()
            } catch (e: Exception) { if (e is CancellationException) throw e; error = safeError(e); bridge.close(); vnc = null }
            publish()
        }
        fun pair() {
            cancelPair()
            val job = scope.launch(start = CoroutineStart.LAZY) {
                val owner = coroutineContext[Job]
                fun current() = pairJob === owner && !closed
                try {
                    voice.stop()
                    withContext(NonCancellable) { router.releaseAll() }
                    if (!current()) throw CancellationException("pairing_cancelled")
                    remote.disconnect()
                    remoteStatus = Availability.NEEDS_SETUP
                    remoteError = null; error = null
                    pairState = "connecting"; publish()
                    val ip = PrivateNetwork.resolve(profile.host)
                    pairing.pair(ip, profile.pairingPort.toInt()) {
                        withContext(Dispatchers.Main.immediate) {
                            if (!current()) throw CancellationException("pairing_cancelled")
                            val pending = CompletableDeferred<String>(); pairCode = pending
                            pairState = "waiting"; publish()
                            awaitPairingCode(pending)
                        }
                    }
                    if (!current()) throw CancellationException("pairing_cancelled")
                    profile = store.read(profile.id)
                    remoteError = null; pairState = "paired"
                } catch (e: Exception) {
                    if (e is CancellationException) throw e
                    if (current()) {
                        remoteError = safeError(e); error = remoteError
                        remoteStatus = Availability.NEEDS_SETUP
                        pairState = "failed"
                    }
                } finally {
                    if (pairJob === owner) {
                        pairCode = null; publish()
                        try { if (pairState == "paired" && !closed) connectRemote(allowPairOwner = true) }
                        finally { if (pairJob === owner) pairJob = null }
                    }
                }
            }
            // Main.immediate may execute before launch returns. Assign ownership
            // first, including for a failure before the first suspension.
            pairJob = job
            job.start()
        }
        fun cancelPair() {
            pairing.cancel(); pairCode?.cancel(); pairCode = null
            pairJob?.cancel(); pairJob = null; pairState = "idle"; publish()
        }
        suspend fun execute(command: TvCommand): CommandOutcome {
            if (closed || !foreground) return CommandOutcome(Delivery.NOT_SENT, null, "not_connected")
            if ((command.code != null && command.code !in 0..65535) || (command.number != null && command.number !in 0..Int.MAX_VALUE.toLong()))
                return CommandOutcome(Delivery.NOT_SENT, null, "invalid_command")
            val reportedName = if (command.kind == CommandKind.SONY) sony.state.buttons.firstOrNull { it.id == command.value }?.name else null
            if (reportedName == "WakeUp") return wake(command.copy(kind = CommandKind.POWER_ON))
            if (reportedName in setOf("TvPower", "Power")) return execute(command.copy(kind = CommandKind.POWER_TOGGLE))
            if (command.kind == CommandKind.POWER_ON) return wake(command)
            if (command.kind == CommandKind.REBOOT && !command.userConfirmed)
                return CommandOutcome(Delivery.NOT_SENT, null, "confirmation_required")
            if (command.kind == CommandKind.SONY && sony.state.buttons.any { it.id == command.value && it.disruptive } && !command.userConfirmed)
                return CommandOutcome(Delivery.NOT_SENT, null, "confirmation_required")
            if (command.kind != CommandKind.KEY_UP && off && command.kind !in setOf(CommandKind.POWER_OFF, CommandKind.POWER_TOGGLE))
                return CommandOutcome(Delivery.NOT_SENT, null, "standby")
            val sonyName = if (command.kind == CommandKind.SONY) sony.state.buttons.firstOrNull { it.id == command.value }?.name else null
            val requestsOff = command.kind == CommandKind.POWER_OFF || sonyName in setOf("PowerOff", "Sleep") ||
                ((command.kind == CommandKind.POWER_TOGGLE || sonyName in setOf("Power", "TvPower")) &&
                    PowerObservation.isOn(sony.state.power, remote.state.value.androidOn.takeIf { remote.state.value.connected }))
            val priorOff = off
            val powerEpoch = if (requestsOff || command.kind == CommandKind.POWER_TOGGLE) ++powerIntentEpoch else powerIntentEpoch
            if (requestsOff) {
                off = true; store.setPowerOffIntent(profile.id, true)
                // Stop future wake attempts before awaiting any network result.
                waking?.cancel(); cancelMacro(); voice.stop(discardAudio = true)
            }
            val result = router.execute(command)
            if (command.kind == CommandKind.KEY && command.code in setOf(23L, 4L)) {
                lastNavigation = command.code!! to result
                android.util.Log.i("TVVNC", "navigation_result transport=${result.transport} delivery=${result.delivery.name}")
            }
            if (requestsOff && powerEpoch == powerIntentEpoch && result.delivery in setOf(Delivery.NOT_SENT, Delivery.REJECTED)) {
                off = priorOff; store.setPowerOffIntent(profile.id, priorOff)
            }
            if (requestsOff && powerEpoch == powerIntentEpoch && result.delivery in setOf(Delivery.SENT, Delivery.CONFIRMED, Delivery.UNKNOWN)) {
                off = true; store.setPowerOffIntent(profile.id, true)
                sony.invalidatePower(); router.releaseAll()
                remote.disconnect(); vnc?.close(); vnc = null; stage = "reconnectPaused"
            }
            if (command.kind == CommandKind.POWER_TOGGLE && !requestsOff && powerEpoch == powerIntentEpoch &&
                result.delivery in setOf(Delivery.SENT, Delivery.CONFIRMED, Delivery.UNKNOWN)) {
                // A toggle is never replayed. Resume observation and connection
                // recovery; only explicit Power On may send a wake sequence.
                off = false; store.setPowerOffIntent(profile.id, false)
                sony.invalidatePower()
                scope.launch { refreshSony(false, powerOnly = true); connectRemote(); ensureVnc() }
            }
            if (command.kind in setOf(CommandKind.INPUT, CommandKind.APP)) vnc?.invalidate()
            if (result.delivery == Delivery.SENT && (command.kind in setOf(CommandKind.VOLUME, CommandKind.MUTE, CommandKind.UNMUTE, CommandKind.INPUT) ||
                command.kind in setOf(CommandKind.KEY, CommandKind.KEY_UP) && command.code in setOf(24L, 25L, 164L)))
                scope.launch { refreshSony(false) }
            if (command.kind == CommandKind.APP && result.delivery in setOf(Delivery.SENT, Delivery.CONFIRMED)) {
                profile = store.update(profile.id) { it.copy(recents = (listOfNotNull(command.value) + it.recents).distinct().take(20)) }
            }
            if (result.errorCode != null) error = result.errorCode
            publish()
            return result
        }
        private suspend fun wake(command: TvCommand): CommandOutcome {
            if (waking?.isActive == true) return CommandOutcome(Delivery.QUEUED, "wake", null)
            ++powerIntentEpoch
            off = false; store.setPowerOffIntent(profile.id, false)
            sony.invalidatePower()
            stage = "waking"; error = null
            wakeOwnerMacro = macroId
            waking = scope.launch(start = CoroutineStart.LAZY) {
                var sonyTried = false
                var detectionTried = false
                val remoteGenerations = mutableSetOf<Long>()
                var wolSent = false
                try {
                    withTimeout(90_000) {
                        while (isActive && !closed && !off && foreground && permissions.networkAllowed()) {
                            if (!sonyTried && sonyPort.accepts(command)) {
                                sonyTried = true; sonyPort.send(command)
                            }
                            if (!wolSent && !profile.mac.isNullOrBlank()) {
                                wolSent = true
                                try { sendWake(profile.host, profile.mac!!) }
                                catch (e: Exception) { if (e is CancellationException) throw e; error = safeError(e) }
                            }
                            val remoteEpoch = remote.connectionGeneration
                            if (remotePort.accepts(command) && remoteGenerations.add(remoteEpoch)) remotePort.send(command, remoteEpoch)
                            // Explicit wake authorizes discovery. A restored Off
                            // intent has no cached method catalog in memory.
                            if (!detectionTried && sony.state.available && sony.state.methods.isEmpty()) {
                                detectionTried = true; refreshSony(true)
                            } else refreshSony(false, powerOnly = true)
                            // Only a post-request observation may finish waking.
                            if (PowerObservation.isOn(sony.state.power, remote.state.value.androidOn.takeIf { remote.state.value.connected })) {
                                connectRemote(); ensureVnc(); refreshSony(true); return@withTimeout
                            }
                            delay(1000)
                        }
                    }
                } catch (_: TimeoutCancellationException) { error = "wake_unconfirmed" }
                catch (e: Exception) { if (e is CancellationException) throw e; error = safeError(e) }
                finally {
                    if (waking === coroutineContext[Job]) { waking = null; wakeOwnerMacro = null }
                    publish()
                }
            }
            waking!!.start(); publish()
            return CommandOutcome(Delivery.QUEUED, "wake", null)
        }
        fun runMacro(macroId: String) {
            val selectedMacro = profile.macros.firstOrNull { it.id == macroId } ?: throw LocalRequestError("macro_missing")
            cancelMacro()
            macro = scope.launch(start = CoroutineStart.LAZY) {
                this@Session.macroId = macroId
                try {
                    selectedMacro.steps.forEachIndexed { index, step ->
                        ensureActive(); macroStep = index.toLong(); publish()
                        withTimeout(step.timeoutSeconds * 1000) {
                            val kind = when (step.action) {
                                MacroAction.WAKE -> CommandKind.POWER_ON
                                MacroAction.HOME -> CommandKind.KEY
                                MacroAction.INPUT -> CommandKind.INPUT
                                MacroAction.APP -> CommandKind.APP
                                MacroAction.KEY -> CommandKind.KEY
                                MacroAction.SONY -> CommandKind.SONY
                                MacroAction.WAIT_FOR_TV -> null
                            }
                            if (kind != null) {
                                val outcome = execute(TvCommand(profile.id, id, kind,
                                    if (step.action == MacroAction.HOME) 3L else if (step.action == MacroAction.KEY) step.value?.toLongOrNull() else null,
                                    step.value, null, null, null, false, false, false))
                                if (outcome.delivery !in setOf(Delivery.QUEUED, Delivery.SENT, Delivery.CONFIRMED)) throw LocalRequestError(outcome.errorCode ?: "macro_failed")
                            }
                            when (step.action) {
                                MacroAction.WAKE, MacroAction.WAIT_FOR_TV -> while (!PowerObservation.isOn(sony.state.power, remote.state.value.androidOn.takeIf { remote.state.value.connected })) { delay(250); ensureActive() }
                                MacroAction.INPUT -> while (!SonyTransport.inputMatches(step.value, sony.state.currentInput)) { delay(250); ensureActive() }
                                // App and Home dispatches have no universal state acknowledgement.
                                // A following observable wait is explicit rather than a guessed delay.
                                else -> Unit
                            }
                        }
                    }
                } catch (e: Exception) {
                    if (e !is CancellationException || e is TimeoutCancellationException) error = "macro_failed"
                } finally {
                    if (macro === coroutineContext[Job]) { macro = null; this@Session.macroId = null; macroStep = null; publish() }
                }
            }
            macro!!.start()
        }
        fun cancelMacro() {
            if (wakeOwnerMacro != null && wakeOwnerMacro == macroId) { waking?.cancel(); wakeOwnerMacro = null }
            macro?.cancel(); macro = null; macroId = null; macroStep = null
        }

        private val remotePort = object : CommandTransport {
            override val id = "remote"
            override val connectionGeneration: Long get() = remote.connectionGeneration
            override fun accepts(command: TvCommand) = remote.state.value.connected && when (command.kind) {
                CommandKind.KEY, CommandKind.KEY_DOWN, CommandKind.KEY_UP, CommandKind.POWER_ON, CommandKind.POWER_OFF, CommandKind.POWER_TOGGLE ->
                    remote.state.value.features and NativeRemoteSession.KEY != 0
                CommandKind.TEXT -> remote.state.value.features and NativeRemoteSession.IME != 0
                CommandKind.SONY -> remote.state.value.features and NativeRemoteSession.KEY != 0 && equivalent(command) != null
                CommandKind.APP -> sony.state.apps.none { it.uri == command.value } && remote.state.value.features and NativeRemoteSession.APP_LINK != 0
                else -> false
            }
            override suspend fun send(command: TvCommand, expectedConnection: Long) = attempt(id) {
                when (command.kind) {
                    CommandKind.KEY, CommandKind.KEY_DOWN, CommandKind.KEY_UP -> remote.key(command.code?.toInt() ?: throw CommandNotSent("unsupported"),
                        when (command.kind) { CommandKind.KEY_DOWN -> 1; CommandKind.KEY_UP -> 2; else -> 3 }, expectedConnection)
                    CommandKind.TEXT -> remote.text(command.value.orEmpty(), command.replaceText, command.editorRevision, expectedConnection)
                    CommandKind.SONY -> remote.key(equivalent(command)!!.code, expectedConnection = expectedConnection)
                    CommandKind.APP -> {
                        val uri = URI(command.value.orEmpty())
                        if (uri.scheme.isNullOrEmpty() || uri.scheme in setOf("file", "javascript", "data", "content")) throw CommandNotSent("invalid_link")
                        remote.launch(uri.toASCIIString(), expectedConnection)
                    }
                    CommandKind.POWER_ON -> remote.key(224, expectedConnection = expectedConnection)
                    CommandKind.POWER_OFF -> remote.key(223, expectedConnection = expectedConnection)
                    CommandKind.POWER_TOGGLE -> remote.key(26, expectedConnection = expectedConnection)
                    else -> throw CommandNotSent("unsupported")
                }
            }
        }
        private fun equivalent(command: TvCommand): SemanticKey? {
            val reported = sony.state.buttons.firstOrNull { it.id == command.value } ?: return null
            return RemoteKeys.all.firstOrNull { key -> key.sony.any { it.equals(reported.name, true) } }
        }
        private val sonyPort = object : CommandTransport {
            override val id = "sony"
            override fun accepts(command: TvCommand) = when (command.kind) {
                CommandKind.KEY -> RemoteKeys.forCode(command.code)?.sony?.any { sony.command(it) != null } == true
                CommandKind.SONY -> sony.state.buttons.any { it.id == command.value }
                CommandKind.INPUT -> sony.state.inputs.any { it.uri == command.value }
                CommandKind.APP -> sony.state.apps.any { it.uri == command.value }
                CommandKind.TEXT -> !command.replaceText && sony.state.methods["appControl.setTextForm"] in setOf("1.0", "1.1")
                CommandKind.POWER_ON -> sony.supports("system", "setPowerStatus") || sony.command("WakeUp") != null
                CommandKind.POWER_OFF -> sony.supports("system", "setPowerStatus") || sony.command("PowerOff") != null
                CommandKind.POWER_TOGGLE -> sony.command("TvPower", "Power") != null
                CommandKind.MUTE, CommandKind.UNMUTE -> sony.supports("audio", "setAudioMute")
                CommandKind.VOLUME -> sony.supports("audio", "setAudioVolume")
                CommandKind.REBOOT -> sony.supports("system", "requestReboot")
                else -> false
            }
            override suspend fun send(command: TvCommand, expectedConnection: Long) = attempt(id) {
                when (command.kind) {
                    CommandKind.KEY -> sony.ircc(sony.command(*RemoteKeys.forCode(command.code)!!.sony.toTypedArray())!!)
                    CommandKind.SONY -> sony.ircc(sony.state.buttons.first { it.id == command.value })
                    CommandKind.INPUT -> sony.input(command.value!!)
                    CommandKind.APP -> sony.launch(command.value!!)
                    CommandKind.TEXT -> sony.text(command.value.orEmpty())
                    CommandKind.POWER_ON -> sony.power(true)
                    CommandKind.POWER_OFF -> sony.power(false)
                    CommandKind.POWER_TOGGLE -> sony.ircc(sony.command("TvPower", "Power")!!)
                    CommandKind.MUTE -> sony.mute(true)
                    CommandKind.UNMUTE -> sony.mute(false)
                    CommandKind.VOLUME -> sony.volume(command.number!!.toInt())
                    CommandKind.REBOOT -> sony.reboot()
                    else -> throw CommandNotSent("unsupported")
                }
            }
        }
        private val vncPort = object : CommandTransport {
            override val id = "vnc"
            override val connectionGeneration: Long get() = vnc?.connectionId ?: 0
            override fun accepts(command: TvCommand) = vnc?.state?.connected == true && when (command.kind) {
                CommandKind.KEY -> RemoteKeys.forCode(command.code)?.rfb != null ||
                    (profile.droidVnc && command.code in setOf(3L, 4L, 24L, 25L, 279L))
                CommandKind.TEXT -> !command.replaceText
                CommandKind.PASTE -> !command.privateText
                else -> false
            }
            override suspend fun send(command: TvCommand, expectedConnection: Long): CommandOutcome {
                val viewer = vnc ?: return CommandOutcome(Delivery.NOT_SENT, id, "transport_unavailable")
                if (viewer.connectionId != expectedConnection)
                    return CommandOutcome(Delivery.NOT_SENT, id, "stale_session")
                suspend fun tap(key: Int): Int {
                    val down = viewer.key(key, true)
                    if (down == 0) return 0
                    val up = viewer.key(key, false)
                    return if (down == 1 && up == 1) 1 else 2
                }
                val result = when (command.kind) {
                    CommandKind.KEY -> when (command.code) {
                        3L -> tap(0xff50)
                        4L -> tap(0xff1b)
                        279L -> tap(0xff63)
                        24L, 25L -> {
                            var delivered = 1
                            try {
                                if (viewer.key(0xffe3, true) != 1) delivered = 2
                                if (delivered == 1 && viewer.key(0xffe9, true) != 1) delivered = 2
                                if (delivered == 1) delivered = tap(if (command.code == 24L) 0xff55 else 0xff56)
                            } finally {
                                withContext(NonCancellable) {
                                    if (viewer.key(0xffe9, false) != 1) delivered = 2
                                    if (viewer.key(0xffe3, false) != 1) delivered = 2
                                }
                            }
                            delivered
                        }
                        else -> tap(RemoteKeys.forCode(command.code)!!.rfb!!)
                    }
                    CommandKind.PASTE -> viewer.clipboard(command.value.orEmpty()) // Setting clipboard is not proof of insertion.
                    CommandKind.TEXT -> {
                        val value = command.value.orEmpty()
                        if (value.length > 8192) return CommandOutcome(Delivery.NOT_SENT, id, "text_too_large")
                        var delivered = 0
                        for (point in value.codePoints().toArray()) {
                            if (closed || selected !== this@Session) return CommandOutcome(if (delivered == 0) Delivery.NOT_SENT else Delivery.UNKNOWN, id, "stale_session")
                            val keysym = when { point == 10 -> 0xff0d; point == 9 -> 0xff09; point <= 255 -> point; else -> 0x01000000 or point }
                            val outcome = tap(keysym)
                            if (outcome != 1) return CommandOutcome(if (delivered == 0 && outcome == 0) Delivery.NOT_SENT else Delivery.UNKNOWN, id, "delivery_unknown")
                            delivered++
                        }
                        1
                    }
                    else -> 0
                }
                return CommandOutcome(when (result) { 0 -> Delivery.NOT_SENT; 1 -> Delivery.SENT; else -> Delivery.UNKNOWN }, id,
                    if (result == 0) "transport_unavailable" else if (result == 2) "delivery_unknown" else null)
            }
        }

        private fun actionAvailability(command: TvCommand): Availability {
            if (closed) return Availability.UNAVAILABLE
            if (!permissions.networkAllowed()) return Availability.PERMISSION_REQUIRED
            if (off && command.kind !in setOf(CommandKind.POWER_ON, CommandKind.POWER_OFF, CommandKind.POWER_TOGGLE))
                return Availability.UNAVAILABLE
            val s = sony.state
            val sonyAvailable = when {
                // A protected app-list read does not establish the permission
                // policy of a separately reported IRCC button. Keep it testable.
                sonyPort.accepts(command) && (s.available || s.errors["system.getPowerStatus"] == "authentication_required") -> Availability.ADVERTISED
                s.errors["system.getPowerStatus"] == "authentication_required" -> Availability.NEEDS_SETUP
                !s.available -> if (sonyAt == 0L) Availability.UNKNOWN else Availability.UNAVAILABLE
                s.errors.values.contains("authentication_required") -> Availability.NEEDS_SETUP
                else -> Availability.UNKNOWN
            }
            val remoteAvailable = when {
                remotePort.accepts(command) -> Availability.READY
                remote.state.value.connected -> Availability.UNSUPPORTED
                else -> CapabilityRouter.liveRemoteAvailability(remote.state.value.connected, remoteStatus)
            }
            val vncAvailable = when {
                vncPort.accepts(command) -> Availability.READY
                vnc?.state?.connected == true -> Availability.UNSUPPORTED
                vnc?.state?.errorCode == "authentication_required" -> Availability.NEEDS_SETUP
                else -> Availability.UNAVAILABLE
            }
            val candidates = mutableListOf(sonyAvailable, remoteAvailable, vncAvailable)
            if (command.kind == CommandKind.POWER_ON && !profile.mac.isNullOrBlank()) candidates.add(Availability.ADVERTISED)
            return CapabilityRouter.bestAvailability(candidates)
        }

        fun snapshot(): SessionSnapshot {
            val s = sony.state; val r = remote.state.value; val screen = (vnc?.state ?: blankScreen()).copy(hidden = !viewerWanted)
            val liveRemoteStatus = CapabilityRouter.liveRemoteAvailability(r.connected, remoteStatus)
            if (remoteError == "network_permission" || screen.errorCode == "network_permission" || s.errors.values.contains("network_permission"))
                permissions.noteNetworkDenial()
            val now = System.currentTimeMillis()
            stage = when {
                closed -> "disconnected"
                !permissions.networkAllowed() -> "permissionRequired"
                off -> "reconnectPaused"
                waking?.isActive == true -> "waking"
                r.connected || screen.connected -> "connected"
                s.available && s.errors.values.contains("authentication_required") -> "needsSetup"
                s.available -> "tvResponding"
                sonyAt > 0 -> "unavailable"
                else -> "connecting"
            }
            val sonyStatus = s.availability(observed = sonyAt != 0L)
            val caps = mutableListOf<CapabilityInfo>()
            fun cap(name: String, state: Availability, transport: String, at: Long = now, detail: String? = null) {
                caps.add(CapabilityInfo(name, state, transport, at, detail))
            }
            cap("screen", if (screen.connected && !screen.stale) Availability.READY else if (screen.connected && screen.frameAt == 0L) Availability.ADVERTISED else Availability.UNAVAILABLE, "vnc", screen.frameAt)
            cap("pointer", if (screen.connected && !screen.stale) { if (profile.pointerVerified) Availability.READY else Availability.ADVERTISED } else Availability.UNAVAILABLE, "vnc", screen.frameAt)
            cap("absoluteVolume", if (sony.supports("audio", "setAudioVolume")) Availability.ADVERTISED else Availability.UNKNOWN, "sony", sonyAt)
            cap("sonyIrcc", if (s.buttons.isNotEmpty()) Availability.ADVERTISED else sonyStatus, "sony", sonyAt)
            cap("androidRemote", liveRemoteStatus, "remote", remoteAt)
            for ((name, flag) in listOf("key" to NativeRemoteSession.KEY, "text" to NativeRemoteSession.IME, "voice" to NativeRemoteSession.VOICE, "appLink" to NativeRemoteSession.APP_LINK))
                cap(name, if (r.connected) { if (r.features and flag != 0) Availability.READY else Availability.UNSUPPORTED } else liveRemoteStatus, "remote", remoteAt)
            cap("apps", if (s.apps.isNotEmpty()) Availability.READY else sonyStatus.takeUnless { it == Availability.READY } ?: Availability.UNKNOWN, "sony", sonyAt)
            cap("inputs", if (s.inputs.isNotEmpty()) Availability.READY else Availability.UNKNOWN, "sony", sonyAt)
            cap("power", if (s.power != null) Availability.READY else Availability.UNKNOWN, "sony", sonyAt)
            cap("wake", if (!profile.mac.isNullOrBlank()) Availability.ADVERTISED else Availability.NEEDS_SETUP, "wol")
            cap("reboot", if (sony.supports("system", "requestReboot")) Availability.ADVERTISED else Availability.UNKNOWN, "sony", sonyAt)
            for ((name, kind) in listOf("powerOn" to CommandKind.POWER_ON, "powerOff" to CommandKind.POWER_OFF, "powerToggle" to CommandKind.POWER_TOGGLE))
                cap(name, actionAvailability(TvCommand(profile.id, id, kind, replaceText = false, privateText = false, userConfirmed = false)), "composite")
            val buttons = RemoteKeys.all.map { key -> TvButton(key.id, key.id, key.code.toLong(), null,
                !off && r.connected && r.features and NativeRemoteSession.KEY != 0, false,
                actionAvailability(TvCommand(profile.id, id, CommandKind.KEY, code = key.code.toLong(), replaceText = false, privateText = false, userConfirmed = false))) } +
                s.buttons.map { it.copy(state = actionAvailability(TvCommand(profile.id, id, CommandKind.SONY, value = it.id, replaceText = false, privateText = false, userConfirmed = false))) }
            return SessionSnapshot(profile.id, id, s.power, s.currentInput, r.application.takeIf { r.connected },
                s.volume ?: r.volume?.toLong()?.takeIf { r.connected }, s.maximumVolume ?: r.maximumVolume?.toLong()?.takeIf { r.connected }, s.muted ?: r.muted.takeIf { r.connected },
                s.model ?: r.model.takeIf { it.isNotBlank() }, s.firmware, r.serviceVersion.takeIf { it.isNotBlank() }, profile.mac ?: s.mac,
                r.editor?.let { EditorInfo(it.application, it.label, it.text, it.start.toLong(), it.end.toLong(), it.revision) }, screen,
                listOf(TransportInfo("sony", sonyStatus, sonyAt, s.errors.values.firstOrNull(), s.latencyMs),
                    TransportInfo("remote", liveRemoteStatus, remoteAt, remoteError, null),
                    TransportInfo("vnc", if (screen.connected) Availability.READY else if (screen.errorCode == "authentication_required") Availability.NEEDS_SETUP else Availability.UNAVAILABLE,
                        screen.frameAt, screen.errorCode, null)),
                caps, buttons, s.inputs.map { it.copy(selected = SonyTransport.inputMatches(it.uri, s.currentInput)) }, s.apps,
                voiceState, pairState, stage, macroId, macroStep, error, snapshotSequence.incrementAndGet(), permissions.networkAllowed())
        }
        fun publish() {
            if (selected !== this) return
            root.launch {
                if (selected === this@Session) {
                    try { flutter.snapshotChanged(snapshot()) }
                    catch (e: Exception) {
                        if (e is CancellationException) throw e
                        android.util.Log.w("TVConsole", "flutter_state_unavailable")
                        if (!closed) close()
                    }
                }
            }
        }
        suspend fun close() = withContext(NonCancellable) {
            if (closed) return@withContext
            val finishingPair = pairJob
            closed = true; cancelMacro(); waking?.cancel(); cancelPair(); voice.dispose()
            scope.cancel(); router.releaseAll(); remote.dispose()
            sony.close()
            vnc?.close(); vnc = null
            listOfNotNull(finishingPair, remoteLoop, vncLoop).joinAll()
            remoteStatus = Availability.UNAVAILABLE; stage = "disconnected"
        }
    }
    companion object {
        fun blankScreen() = ScreenInfo(null, 0, 0, 0, 0, false, true, null)
        suspend fun awaitPairingCode(pending: Deferred<String>, timeoutMs: Long = 120_000): String =
            withTimeoutOrNull(timeoutMs) { pending.await() } ?: throw LocalRequestError("pairing_timeout")
        fun safeError(error: Exception): String = when {
            error is CommandNotSent -> error.reason
            error is DeliveryUnknown || error is HttpDeliveryUnknown -> "delivery_unknown"
            error is SecurityException && error.message == "identity_changed" -> "identity_changed"
            error is java.security.cert.CertificateException || error.cause is java.security.cert.CertificateException -> "identity_changed"
            error is javax.net.ssl.SSLException -> "secure_connection_failed"
            error is java.io.IOException && error.message in setOf("pairing_rejected", "pairing_unavailable", "pairing_protocol_error") -> error.message!!
            error is IllegalArgumentException && error.message == "pairing_rejected" -> "pairing_rejected"
            else -> SonyTransport.safeError(error)
        }
        suspend fun attempt(transport: String, block: suspend () -> Unit): CommandOutcome = try {
            block(); CommandOutcome(Delivery.SENT, transport, null)
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            val code = safeError(e)
            val delivery = when {
                e is CommandNotSent -> Delivery.NOT_SENT
                e is io.github.ddagunts.screencast.androidtv.IdentityStorageException -> Delivery.NOT_SENT
                e is LocalRequestError && e.code in setOf("secure_storage_failed", "credential_storage_failed", "credential_storage_invalid", "profile_storage_failed") -> Delivery.NOT_SENT
                e is SonyError && e.status in setOf(2, 41402) -> Delivery.UNKNOWN
                e is SonyError -> Delivery.REJECTED
                e is LocalRequestError && e.code in setOf("authentication_required", "unsupported", "invalid_link") -> Delivery.REJECTED
                e is java.net.ConnectException || e is java.net.UnknownHostException -> Delivery.NOT_SENT
                e is IllegalArgumentException -> Delivery.NOT_SENT
                else -> Delivery.UNKNOWN
            }
            CommandOutcome(delivery, transport, if (e is java.net.ConnectException) "transport_unavailable" else code)
        }
        fun wakePacket(mac: String): ByteArray {
            require(mac.replace(":", "").replace("-", "").matches(Regex("[0-9a-fA-F]{12}")))
            val bytes = mac.replace(":", "").replace("-", "").chunked(2).map { it.toInt(16).toByte() }.toByteArray()
            require(bytes.size == 6)
            return ByteArray(102) { if (it < 6) 0xff.toByte() else bytes[(it - 6) % 6] }
        }
        suspend fun sendWake(host: String, mac: String) = withContext(Dispatchers.IO) {
            val packet = wakePacket(mac)
            // A sleeping TV can disappear from mDNS. WOL is addressed by MAC
            // and does not require a successful hostname lookup.
            val target = try { InetAddress.getByName(PrivateNetwork.resolve(host)) }
                catch (_: UnknownHostException) { null }
            val broadcasts = NetworkInterface.getNetworkInterfaces().toList().filter { it.isUp && !it.isLoopback }
                .flatMap { it.interfaceAddresses }.filter { iface ->
                    val local = iface.address.address; val remote = target?.address
                    local.size == 4 && iface.address.isSiteLocalAddress && (remote == null || remote.size == 4 && (0 until 4).all { i ->
                        val shift = (iface.networkPrefixLength.toInt() - i * 8).coerceIn(0, 8)
                        val mask = (0xff shl (8 - shift)) and 0xff
                        local[i].toInt() and mask == remote[i].toInt() and mask
                    })
                }.mapNotNull { it.broadcast }.distinct()
            if (broadcasts.isEmpty()) throw LocalRequestError("network_unavailable")
            DatagramSocket().use { socket ->
                socket.broadcast = true
                (broadcasts + listOfNotNull(target)).forEach { ip -> socket.send(DatagramPacket(packet, packet.size, ip, 9)) }
            }
        }
    }
}
