package dev.tvvnc.tv_vnc.core

import java.security.KeyFactory
import java.security.SecureRandom
import java.security.spec.X509EncodedKeySpec
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

/** Sony v1.1 interoperable envelope: RSA-PKCS1(keyHex:ivHex), AES-128-CBC
 * text with PKCS7 padding. Wire format cross-checked against braviaproapi's
 * Encryption implementation; this does not authenticate the HTTP endpoint. */
class SonyTextCipher(publicKey: String) : AutoCloseable {
    private val key = ByteArray(16).also { SecureRandom().nextBytes(it) }
    private val iv = ByteArray(16).also { SecureRandom().nextBytes(it) }
    val encryptedKey: String
    private var closed = false
    private var used = false
    init {
        val rsa = KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(Base64.getDecoder().decode(publicKey)))
        val transport = (key.hex() + ":" + iv.hex()).toByteArray(Charsets.US_ASCII)
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding").apply { init(Cipher.ENCRYPT_MODE, rsa) }
        try { encryptedKey = Base64.getEncoder().encodeToString(cipher.doFinal(transport)) }
        finally { transport.fill(0) }
    }
    fun encrypt(text: String): String {
        check(!closed && !used)
        used = true
        val bytes = text.toByteArray(Charsets.UTF_8)
        val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding").apply {
            init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), IvParameterSpec(this@SonyTextCipher.iv))
        }
        return try { Base64.getEncoder().encodeToString(cipher.doFinal(bytes)) } finally { bytes.fill(0) }
    }
    override fun close() { closed = true; key.fill(0); iv.fill(0) }
    private fun ByteArray.hex() = joinToString("") { "%02x".format(it.toInt() and 255) }
}
