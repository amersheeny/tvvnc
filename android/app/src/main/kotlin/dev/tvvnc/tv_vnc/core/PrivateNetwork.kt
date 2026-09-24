package dev.tvvnc.tv_vnc.core

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.IOException
import java.net.InetAddress
import java.net.URL

class LocalRequestError(val code: String) : IOException(code) {
    override fun toString() = code
}
class HttpDeliveryUnknown : IOException("delivery_unknown")

object PrivateNetwork {
    fun isLocal(address: InetAddress): Boolean {
        if (address.isAnyLocalAddress || address.isLoopbackAddress || address.isMulticastAddress) return false
        val bytes = address.address
        return address.isSiteLocalAddress || address.isLinkLocalAddress ||
            (bytes.size == 16 && (bytes[0].toInt() and 0xfe) == 0xfc)
    }
    suspend fun resolve(host: String): String = withContext(Dispatchers.IO) {
        if (host.isBlank() || host.length > 253 || host.any { it.isWhitespace() } ||
            host.contains('/') || host.contains('@') || host.contains('?') || host.contains('#'))
            throw LocalRequestError("invalid_address")
        val addresses = InetAddress.getAllByName(host.removeSurrounding("[", "]"))
        if (addresses.isEmpty() || addresses.any { !isLocal(it) }) throw LocalRequestError("non_local_address")
        (addresses.firstOrNull { it.address.size == 4 } ?: addresses.first()).hostAddress!!
    }
}

/** A fresh DNS validation precedes each connection. The HTTP socket is pinned
 * to that numeric address, with bounded IO and no automatic replay. */
class LocalHttp(private val host: String, private val psk: () -> String?,
    private val cookie: () -> String? = { null }) {
    suspend fun post(path: String, body: ByteArray, soap: Boolean = false,
        authorization: String? = null, registeredCookie: ((String) -> Unit)? = null,
        useSavedCredentials: Boolean = true): JSONObject = withContext(Dispatchers.IO) {
        require(path.startsWith("/sony/") && !path.contains(".."))
        val ip = PrivateNetwork.resolve(host)
        val url = URL("http", ip, 80, path)
        val headers = mutableMapOf("Content-Type" to if (soap) "text/xml; charset=utf-8" else "application/json")
            if (soap) headers["SOAPACTION"] = "\"urn:schemas-sony-com:service:IRCC:1#X_SendIRCC\""
            if (useSavedCredentials) {
                val savedCookie = cookie()?.takeIf { it.isNotEmpty() }
                if (savedCookie != null) headers["Cookie"] = savedCookie
                else psk()?.takeIf { it.isNotEmpty() }?.let { headers["X-Auth-PSK"] = it }
            }
            authorization?.let { headers["Authorization"] = it }
            val response = BoundedHttp.exchange(url, InetAddress.getByName(ip), headers, body, 2_097_152)
            val status = response.status
            if (status in 300..399) throw LocalRequestError("redirect_refused")
            if (status == 401 || status == 403) throw LocalRequestError("authentication_required")
            if (status !in 200..299) throw LocalRequestError("http_$status")
            val result = if (soap) JSONObject().put("result", org.json.JSONArray()) else try {
                JSONObject(response.bytes.toString(Charsets.UTF_8))
            } catch (_: org.json.JSONException) { throw LocalRequestError("invalid_sony_response") }
            if (!result.has("error") && registeredCookie != null) {
                val cookies = response.cookies.flatMap { java.net.HttpCookie.parse(it) }
                    .filter { it.name == "auth" && it.value.matches(Regex("[A-Za-z0-9+/_=.%:-]{1,4096}")) }
                if (cookies.isNotEmpty()) registeredCookie(cookies.joinToString("; ") { "${it.name}=${it.value}" })
            }
            result
    }

    suspend fun icon(location: String): ByteArray = withContext(Dispatchers.IO) {
        val input = URL(location)
        if (input.protocol !in setOf("http", "https") || input.userInfo != null) throw LocalRequestError("icon_address_refused")
        val ip = PrivateNetwork.resolve(input.host)
        if (ip != PrivateNetwork.resolve(host)) throw LocalRequestError("icon_address_refused")
        val pinned = URL(input.protocol, ip, input.port, input.file)
            val response = BoundedHttp.exchange(pinned, InetAddress.getByName(ip), emptyMap(), null, 262144)
            if (response.status !in 200..299) throw LocalRequestError("icon_unavailable")
            val bytes = response.bytes
            val bounds = android.graphics.BitmapFactory.Options().apply { inJustDecodeBounds = true }
            android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            if (bounds.outWidth !in 1..2048 || bounds.outHeight !in 1..2048) throw LocalRequestError("icon_invalid")
            bytes
    }
}
