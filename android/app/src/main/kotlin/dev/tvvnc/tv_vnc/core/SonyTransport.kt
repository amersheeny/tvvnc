package dev.tvvnc.tv_vnc.core

import dev.tvvnc.tv_vnc.bridge.*
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

class SonyError(val method: String, val status: Int) : IOException("sony_$status")
data class SonySnapshot(
    val available: Boolean = false, val power: String? = null, val model: String? = null,
    val firmware: String? = null, val mac: String? = null, val volume: Long? = null,
    val maximumVolume: Long? = null, val muted: Boolean? = null, val currentInput: String? = null,
    val buttons: List<TvButton> = emptyList(), val inputs: List<TvInput> = emptyList(),
    val apps: List<TvApplication> = emptyList(), val methods: Map<String, String> = emptyMap(),
    val errors: Map<String, String> = emptyMap(), val latencyMs: Long? = null,
) {
    fun availability(observed: Boolean): Availability = when {
        errors.values.any { it == "authentication_required" } -> Availability.NEEDS_SETUP
        power != null || available -> Availability.READY
        !observed -> Availability.UNKNOWN
        else -> Availability.UNAVAILABLE
    }
}

/** Sony semantics are discovered from this TV. Static names below map semantic
 * controls to reported command names, never substitute hard-coded IRCC values. */
class SonyTransport(private val host: String, psk: () -> String?, cookie: () -> String? = { null }) {
    private val http = LocalHttp(host, psk, cookie)
    private val sequence = AtomicInteger()
    private val iconLocations = java.util.concurrent.ConcurrentHashMap<String, String>()
    private val iconSlots = kotlinx.coroutines.sync.Semaphore(3)
    private val textLock = Mutex()
    private var textPublicKey: String? = null
    @Volatile var state = SonySnapshot(); private set
    private val powerEpoch = AtomicLong()
    fun invalidatePower() { powerEpoch.incrementAndGet(); state = state.copy(power = null) }

    suspend fun call(service: String, method: String, params: JSONArray = JSONArray(), version: String? = null): JSONArray {
        require(service in SERVICES || service in setOf("guide", "encryption", "accessControl"))
        val request = JSONObject().put("method", method).put("params", params)
            .put("version", version ?: state.methods["$service.$method"] ?: "1.0")
            .put("id", sequence.updateAndGet { if (it == Int.MAX_VALUE) 1 else it + 1 })
        val response = http.post("/sony/$service", request.toString().toByteArray())
        if (response.optInt("id", -1) != request.getInt("id")) throw LocalRequestError("invalid_sony_response")
        response.optJSONArray("error")?.let { throw SonyError(method, it.optInt(0, -1)) }
        return response.optJSONArray("result") ?: response.optJSONArray("results") ?: throw LocalRequestError("invalid_sony_response")
    }

    suspend fun discover(): SonySnapshot = coroutineScope {
        val methods = linkedMapOf<String, String>()
        val errors = linkedMapOf<String, String>()
        // The guide endpoint returns [] on some consumer BRAVIAs. Per-service
        // discovery remains authoritative in that case.
        for (service in SERVICES) {
            try {
                val versions = call(service, "getVersions", version = "1.0").optJSONArray(0) ?: JSONArray().put("1.0")
                for (i in 0 until minOf(versions.length(), 8)) {
                    val version = versions.optString(i)
                    val rows = call(service, "getMethodTypes", JSONArray().put(version), "1.0")
                    for (j in 0 until rows.length()) {
                        val row = rows.optJSONArray(j) ?: continue
                        val name = row.optString(0)
                        val v = row.optString(row.length() - 1)
                        // Prefer the implemented v1.0 shape when offered. Other
                        // versions are retained for explicit versioned adapters.
                        if (!methods.containsKey("$service.$name") || v == "1.0") methods["$service.$name"] = v
                    }
                }
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                errors["$service.discovery"] = safeError(e)
            }
        }
        val remote = try {
            val data = call("system", "getRemoteControllerInfo", version = "1.0")
            val items = data.optJSONArray(1) ?: JSONArray()
            (0 until items.length()).mapNotNull { i ->
                val item = items.optJSONObject(i) ?: return@mapNotNull null
                val name = item.optString("name")
                val code = item.optString("value")
                if (name.isBlank() || name.length > 160 || !code.matches(Regex("[A-Za-z0-9+/=]{4,128}"))) return@mapNotNull null
                TvButton("sony:$name", name, null, code, false,
                    listOf("Demo", "Forced", "Reset", "Reboot", "Delete", "Install").any { name.contains(it, true) },
                    dev.tvvnc.tv_vnc.bridge.Availability.ADVERTISED)
            }
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            errors["system.getRemoteControllerInfo"] = safeError(e); emptyList()
        }
        state = state.copy(available = remote.isNotEmpty() || methods.isNotEmpty(), methods = methods,
            buttons = remote, errors = errors)
        refresh(includeCatalogs = true)
    }

    suspend fun refresh(includeCatalogs: Boolean = false, powerOnly: Boolean = false): SonySnapshot {
        val observedPowerEpoch = powerEpoch.get()
        val errors = state.errors.toMutableMap()
        var responded = false
        suspend fun query(service: String, method: String, params: JSONArray = JSONArray()): JSONArray? = try {
            call(service, method, params).also { responded = true; errors.remove("$service.$method") }
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            errors["$service.$method"] = safeError(e); null
        }
        val started = System.nanoTime()
        val power = query("system", "getPowerStatus")?.optJSONObject(0)?.text("status")
        val latency = (System.nanoTime() - started) / 1_000_000
        var next = state.copy(power = when (power) { "active" -> "on"; "standby" -> "standby"; else -> null },
            available = state.available || power != null, latencyMs = if (power != null) latency else null)
        // Standby queries must not open app/capture sessions or accidentally wake.
        if (power != "standby" && !powerOnly) {
            val volumes = query("audio", "getVolumeInformation")?.optJSONArray(0)
            val volume = volumes?.let { items -> (0 until items.length()).mapNotNull { items.optJSONObject(it) }
                .firstOrNull { it.optString("target") == "speaker" } ?: items.optJSONObject(0) }
            next = next.copy(volume = volume?.text("volume")?.toLongOrNull(),
                maximumVolume = volume?.optLong("maxVolume", 100),
                muted = if (volume?.has("mute") == true) volume.optBoolean("mute") else null)
            val content = query("avContent", "getPlayingContentInfo")?.optJSONObject(0)
            next = next.copy(currentInput = content?.text("uri"))
            if (includeCatalogs || state.power != "on" && power == "active") {
                val info = query("system", "getSystemInformation")?.optJSONObject(0)
                val interfaceInfo = query("system", "getInterfaceInformation")?.optJSONObject(0)
                val network = query("system", "getNetworkSettings", JSONArray().put(JSONObject().put("netif", "")))?.optJSONArray(0)
                val ip = PrivateNetwork.resolve(host)
                val activeInterface = network?.let { array -> (0 until array.length()).mapNotNull { array.optJSONObject(it) }
                    .firstOrNull { it.text("ipAddrV4") == ip || it.text("ipAddrV6") == ip } }
                next = next.copy(model = info?.text("model") ?: interfaceInfo?.text("modelName"),
                    firmware = info?.text("softwareVersion") ?: info?.text("firmwareVersion"),
                    mac = activeInterface?.text("hwAddr"))
                val rawInputs = query("avContent", "getCurrentExternalInputsStatus")?.optJSONArray(0)
                if (rawInputs != null) {
                    val inputs = (0 until rawInputs.length()).mapNotNull { i ->
                        val item = rawInputs.optJSONObject(i) ?: return@mapNotNull null
                        val uri = item.text("uri") ?: return@mapNotNull null
                        TvInput(uri, item.text("title") ?: uri, item.text("label"),
                            item.optBoolean("connection"), uri == next.currentInput)
                    }.toMutableList()
                    if (state.buttons.any { it.name == "Tv" }) inputs.add(0, TvInput("command:Tv", "TV", null, true,
                        next.currentInput?.startsWith("tv:") == true))
                    next = next.copy(inputs = inputs)
                }
                val rawApps = query("appControl", "getApplicationList")?.optJSONArray(0)
                if (rawApps != null) next = next.copy(apps = (0 until minOf(rawApps.length(), 1000)).mapNotNull { i ->
                    val item = rawApps.optJSONObject(i) ?: return@mapNotNull null
                    val uri = item.text("uri") ?: return@mapNotNull null
                    item.text("icon")?.let { iconLocations[uri] = it }
                    TvApplication(uri, item.text("title") ?: uri, uri, null, null)
                })
            }
        }
        if (next.inputs.isEmpty()) next = next.copy(inputs = reportedInputFallback(next.buttons))
        state = next.copy(errors = errors, available = responded,
            power = next.power.takeIf { observedPowerEpoch == powerEpoch.get() })
        return state
    }

    fun command(vararg names: String): TvButton? = names.firstNotNullOfOrNull { name -> state.buttons.firstOrNull { it.name.equals(name, true) } }
    suspend fun ircc(button: TvButton) {
        val code = button.sonyCode ?: throw LocalRequestError("unsupported")
        require(code.matches(Regex("[A-Za-z0-9+/=]{4,128}")))
        val body = """<?xml version="1.0"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1"><IRCCCode>$code</IRCCCode></u:X_SendIRCC></s:Body></s:Envelope>"""
        http.post("/sony/IRCC", body.toByteArray(), true)
    }
    suspend fun power(on: Boolean) {
        if (supports("system", "setPowerStatus")) call("system", "setPowerStatus", JSONArray().put(JSONObject().put("status", on)))
        else ircc(command(if (on) "WakeUp" else "PowerOff") ?: throw LocalRequestError("unsupported"))
    }
    suspend fun mute(muted: Boolean) { call("audio", "setAudioMute", JSONArray().put(JSONObject().put("status", muted))) }
    suspend fun volume(level: Int) {
        require(level in 0..(state.maximumVolume ?: 100).toInt())
        call("audio", "setAudioVolume", JSONArray().put(JSONObject().put("target", "speaker").put("volume", level.toString())))
    }
    suspend fun input(uri: String) {
        require(state.inputs.any { it.uri == uri })
        if (uri.startsWith("command:")) {
            val name = uri.removePrefix("command:")
            require(name == "Tv" || name.matches(Regex("Hdmi[0-9]+", RegexOption.IGNORE_CASE)))
            ircc(command(name) ?: throw LocalRequestError("unsupported"))
        } else {
            call("avContent", "setPlayContent", JSONArray().put(JSONObject().put("uri", uri)))
        }
    }
    suspend fun launch(uri: String) {
        require(state.apps.any { it.uri == uri })
        call("appControl", "setActiveApp", JSONArray().put(JSONObject().put("uri", uri)))
    }
    suspend fun reboot() { call("system", "requestReboot") }
    suspend fun text(value: String) = textLock.withLock {
        require(value.toByteArray().size <= 65536)
        when (state.methods["appControl.setTextForm"]) {
            "1.0" -> call("appControl", "setTextForm", JSONArray().put(value), "1.0")
            "1.1" -> {
                val key = textPublicKey ?: run {
                    val publicKey = call("encryption", "getPublicKey", version = "1.0").optJSONObject(0)?.text("publicKey")
                        ?: throw LocalRequestError("encryption_unavailable")
                    publicKey.also { textPublicKey = it }
                }
                try { SonyTextCipher(key).use { cipher ->
                    call("appControl", "setTextForm", JSONArray().put(JSONObject()
                        .put("text", cipher.encrypt(value)).put("encKey", cipher.encryptedKey)), "1.1")
                } }
                catch (e: SonyError) {
                    if (e.status == 40002) textPublicKey = null
                    throw e // Never replay an uncertain text operation.
                }
            }
            else -> throw LocalRequestError("unsupported")
        }
        Unit
    }
    suspend fun close() = textLock.withLock { textPublicKey = null }
    suspend fun icon(appId: String): ByteArray? {
        if (state.apps.none { it.id == appId }) throw LocalRequestError("unsupported")
        val uri = iconLocations[appId] ?: return null
        iconSlots.acquire()
        return try { http.icon(uri) } finally { iconSlots.release() }
    }
    suspend fun register(clientId: String, pin: String?): String {
        if (pin != null) require(pin.matches(Regex("[0-9]{4,8}")))
        val request = JSONObject().put("method", "actRegister").put("id", 1).put("version", "1.0")
            .put("params", JSONArray().put(JSONObject().put("clientid", "TVConsole:$clientId")
                .put("nickname", "TV Console").put("level", "private"))
                .put(JSONArray().put(JSONObject().put("value", "yes").put("function", "WOL"))))
        val auth = pin?.let { "Basic " + android.util.Base64.encodeToString(":$it".toByteArray(), android.util.Base64.NO_WRAP) }
        var receivedCookie: String? = null
        val response = http.post("/sony/accessControl", request.toString().toByteArray(), authorization = auth,
            registeredCookie = { receivedCookie = it }, useSavedCredentials = false)
        response.optJSONArray("error")?.let { throw SonyError("actRegister", it.optInt(0, -1)) }
        return receivedCookie ?: throw LocalRequestError("registration_unconfirmed")
    }
    fun supports(service: String, method: String) = state.methods.containsKey("$service.$method")
    companion object {
        internal fun inputMatches(requested: String?, actual: String?): Boolean {
            if (requested == null || actual == null) return false
            if (requested == actual) return true
            if (requested == "command:Tv") return actual.startsWith("tv:")
            val port = Regex("command:Hdmi([0-9]+)", RegexOption.IGNORE_CASE).matchEntire(requested)?.groupValues?.get(1)
                ?: return false
            return actual.startsWith("extInput:hdmi?", true) && actual.substringAfter('?').split('&').contains("port=$port")
        }
        internal fun reportedInputFallback(buttons: List<TvButton>): List<TvInput> = buttons.mapNotNull { button ->
            when {
                button.name == "Tv" -> TvInput("command:Tv", "TV", null, false, false)
                button.name.matches(Regex("Hdmi[0-9]+", RegexOption.IGNORE_CASE)) ->
                    TvInput("command:${button.name}", button.name, null, false, false)
                else -> null
            }
        }.distinctBy { it.uri }
        private val SERVICES = setOf("system", "audio", "avContent", "appControl")
        fun safeError(e: Exception): String = when (e) {
            is SonyError -> when (e.status) {
                403, 401 -> "authentication_required"
                12, 14, 15, 501 -> "unsupported"
                7 -> if (e.method == "setTextForm") "no_editor" else "sony_7"
                else -> "sony_${e.status}"
            }
            is LocalRequestError -> e.code
            is io.github.ddagunts.screencast.androidtv.CommandNotSent -> e.reason
            is io.github.ddagunts.screencast.androidtv.DeliveryUnknown -> "delivery_unknown"
            is io.github.ddagunts.screencast.androidtv.IdentityStorageException -> e.code
            is java.net.SocketTimeoutException -> "timeout"
            is java.net.ConnectException -> "connection_refused"
            is java.net.UnknownHostException -> "address_unresolved"
            is java.net.NoRouteToHostException -> "network_route_unavailable"
            is SecurityException -> if (e.message == "identity_changed") "identity_changed" else "network_permission"
            is java.net.SocketException -> if (e.message?.contains("EACCES") == true || e.message?.contains("EPERM") == true ||
                e.message?.contains("Permission denied", true) == true) "network_permission" else "connection_failed"
            else -> "connection_failed"
        }
    }
}
private fun JSONObject.text(key: String): String? = if (isNull(key)) null else optString(key).takeIf { it.isNotBlank() && it != "null" }
