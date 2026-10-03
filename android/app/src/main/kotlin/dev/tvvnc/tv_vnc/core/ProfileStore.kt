package dev.tvvnc.tv_vnc.core

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import dev.tvvnc.tv_vnc.bridge.*
import io.github.ddagunts.screencast.androidtv.KeystoreIdentity
import io.github.ddagunts.screencast.androidtv.IdentityStorageException
import org.json.JSONArray
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

private inline fun <T> storageAccess(block: () -> T): T = try { block() }
    catch (error: LocalRequestError) { throw error }
    catch (error: IdentityStorageException) { throw LocalRequestError(error.code) }
    catch (_: Exception) { throw LocalRequestError("secure_storage_failed") }

class SecretStore(context: Context) {
    internal val prefs = context.getSharedPreferences("tvvnc.profiles", Context.MODE_PRIVATE)
    @Synchronized private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey("tvvnc.storage", null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder("tvvnc.storage", KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setKeySize(256).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
        }.generateKey()
    }
    @Synchronized fun get(id: String): String? = storageAccess {
        val saved = prefs.getString(id, null) ?: return@storageAccess null
        val bytes = Base64.decode(saved, Base64.NO_WRAP)
        if (bytes.size < 28) throw LocalRequestError("credential_storage_invalid")
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes.copyOfRange(0, 12)))
        cipher.updateAAD(id.toByteArray())
        cipher.doFinal(bytes, 12, bytes.size - 12).toString(Charsets.UTF_8)
    }
    @Synchronized fun put(id: String, value: String?) = storageAccess {
        val editor = prefs.edit()
        stage(editor, id, value)
        if (!editor.commit()) throw LocalRequestError("credential_storage_failed")
    }
    internal fun stage(editor: android.content.SharedPreferences.Editor, id: String, value: String?) = storageAccess {
        if (value == null || value.isEmpty()) editor.remove(id) else {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key())
            cipher.updateAAD(id.toByteArray())
            editor.putString(id, Base64.encodeToString(cipher.iv + cipher.doFinal(value.toByteArray()), Base64.NO_WRAP))
        }
    }
    fun has(id: String) = storageAccess { prefs.contains(id) }
}

class ProfileStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("tvvnc.profiles", Context.MODE_PRIVATE)
    val secrets = SecretStore(context)
    // In-flight registrations exist only for this process. Revisions are not
    // credentials and need not survive a process restart.
    private val sonyAuthRevisions = mutableMapOf<String, Long>()
    @Synchronized fun sonyAuthRevision(id: String): Long {
        if (!prefs.contains("profile:$id")) throw LocalRequestError("profile_missing")
        return sonyAuthRevisions[id] ?: 0L
    }
    @Synchronized fun saveSonyCookie(id: String, revision: Long, cookie: String) {
        if (sonyAuthRevision(id) != revision) throw LocalRequestError("stale_session")
        secrets.put("$id:sonyCookie", cookie)
    }

    @Synchronized fun list(): List<TvProfile> = storageAccess { prefs.all.keys.filter { it.startsWith("profile:") }
        .map { read(it.removePrefix("profile:")) }.sortedBy { it.name.lowercase() }
    }

    /** The app owns recents; a settings form must not replace them with its
     * older snapshot while a launch completes. */
    @Synchronized fun saveUser(profile: TvProfile, credentials: TvCredentials?): TvProfile =
        save(if (prefs.contains("profile:${profile.id}")) profile.copy(recents = read(profile.id).recents) else profile, credentials)
    @Synchronized fun update(id: String, edit: (TvProfile) -> TvProfile): TvProfile = save(edit(read(id)), null)

    @Synchronized fun read(id: String): TvProfile = storageAccess {
        val raw = prefs.getString("profile:$id", null) ?: throw LocalRequestError("profile_missing")
        // Migrate development profiles written before metadata encryption. No
        // credentials were plaintext; metadata now receives the same protection.
        val json = if (raw.startsWith("{")) raw else secrets.get("profile:$id") ?: throw LocalRequestError("profile_missing")
        val data = JSONObject(json)
        if (raw.startsWith("{")) secrets.put("profile:$id", json)
        fun strings(key: String) = data.optJSONArray(key)?.let { array -> (0 until array.length()).map { array.getString(it) } } ?: emptyList()
        val macros = data.optJSONArray("macros") ?: JSONArray()
        TvProfile(id, data.getString("name"), data.getString("host"),
            data.optLong("vncPort", 5900), data.optLong("remotePort", 6466), data.optLong("pairingPort", 6467),
            data.optString("mac").takeIf { it.isNotBlank() }, secrets.has("$id:vnc"), secrets.has("$id:sony") || secrets.has("$id:sonyCookie"),
            KeystoreIdentity(context, id).pin() != null, strings("layout"), strings("favorites"), strings("recents"),
            (0 until macros.length()).map { n ->
                val macro = macros.getJSONObject(n)
                val steps = macro.getJSONArray("steps")
                TvMacro(macro.getString("id"), macro.getString("name"), (0 until steps.length()).map { j ->
                    val step = steps.getJSONObject(j)
                    MacroStep(MacroAction.entries.first { it.name == step.getString("action") },
                        step.optString("value").takeIf { it.isNotEmpty() }, step.optLong("timeout", 90))
                })
            }, data.optBoolean("droidVnc", false), data.optBoolean("pointerVerified", false))
    }
    @Synchronized fun save(profile: TvProfile, credentials: TvCredentials?): TvProfile {
        require(profile.id.matches(Regex("[A-Za-z0-9_-]{1,80}"))) { "invalid_profile_id" }
        require(profile.name.isNotBlank() && profile.name.length <= 120) { "invalid_name" }
        require(listOf(profile.vncPort, profile.remotePort, profile.pairingPort).all { it in 1..65535 }) { "invalid_port" }
        require(profile.host.isNotBlank() && profile.host.length <= 253) { "invalid_address" }
        if (!profile.mac.isNullOrBlank()) require(profile.mac.replace(":", "").replace("-", "").matches(Regex("[0-9a-fA-F]{12}"))) { "invalid_mac" }
        require(profile.macros.size <= 100 && profile.macros.all { it.steps.size <= 50 && it.steps.all { s -> s.timeoutSeconds in 1..300 } })
        require(profile.macros.all { it.name.isNotBlank() && it.name.length <= 120 && it.id.matches(Regex("[A-Za-z0-9_-]{1,80}")) &&
            it.steps.all { step -> (step.value?.length ?: 0) <= 8192 && (step.action != MacroAction.KEY || step.value?.toLongOrNull()?.let { code -> code in 0..65535 } == true) } })
        return storageAccess {
        val hostChanged = prefs.contains("profile:${profile.id}") && read(profile.id).host != profile.host.trim()
        val data = JSONObject().put("name", profile.name).put("host", profile.host.trim())
            .put("vncPort", profile.vncPort).put("remotePort", profile.remotePort).put("pairingPort", profile.pairingPort)
            .put("mac", profile.mac.orEmpty()).put("layout", JSONArray(profile.layout))
            .put("droidVnc", profile.droidVnc).put("pointerVerified", profile.pointerVerified)
            .put("favorites", JSONArray(profile.favorites)).put("recents", JSONArray(profile.recents.take(20)))
            .put("macros", JSONArray(profile.macros.map { m -> JSONObject().put("id", m.id).put("name", m.name)
                .put("steps", JSONArray(m.steps.map { s -> JSONObject().put("action", s.action.name)
                    .put("value", s.value.orEmpty()).put("timeout", s.timeoutSeconds) })) }))
        val editor = prefs.edit()
        secrets.stage(editor, "profile:${profile.id}", data.toString())
        credentials?.vncPassword?.let { secrets.stage(editor, "${profile.id}:vnc", it) }
        credentials?.sonyKey?.let { secrets.stage(editor, "${profile.id}:sony", it) }
        if (credentials?.sonyKey != null || hostChanged) editor.remove("${profile.id}:sonyCookie")
        if (!editor.commit()) throw LocalRequestError("profile_storage_failed")
        if (credentials?.sonyKey != null || hostChanged) {
            sonyAuthRevisions[profile.id] = (sonyAuthRevisions[profile.id] ?: 0L) + 1
        }
        read(profile.id)
        }
    }
    @Synchronized fun forget(id: String) = storageAccess {
        sonyAuthRevisions[id] = (sonyAuthRevisions[id] ?: 0L) + 1
        KeystoreIdentity(context, id).forget()
        if (!prefs.edit().remove("$id:vnc").remove("$id:sony").remove("$id:sonyCookie").remove("profile:$id")
            .remove("off:$id").remove("connect:$id").commit()) throw LocalRequestError("profile_storage_failed")
    }
    fun setPowerOffIntent(id: String, off: Boolean) = storageAccess {
        if (!prefs.edit().putBoolean("off:$id", off).commit()) throw LocalRequestError("profile_storage_failed")
    }
    fun powerOffIntent(id: String) = storageAccess { prefs.getBoolean("off:$id", false) }
    fun setConnectIntent(id: String, connected: Boolean) = storageAccess {
        if (!prefs.edit().putBoolean("connect:$id", connected).commit()) throw LocalRequestError("profile_storage_failed")
    }
    fun connectIntent(id: String) = storageAccess { prefs.getBoolean("connect:$id", false) }
}
