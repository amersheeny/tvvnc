package dev.tvvnc.tv_vnc.core

import org.junit.Assert.*
import org.junit.Test
import java.security.KeyPairGenerator
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

class SonyTextCipherTest {
    @Test fun interoperableEnvelopeCanBeDecodedWithoutClientState() {
        val pair = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
        val publicKey = Base64.getEncoder().encodeToString(pair.public.encoded)
        // Independent receiver follows the Sony wire contract: the RSA block
        // carries ASCII keyHex:ivHex, not raw AES bytes.
        val rsa = Cipher.getInstance("RSA/ECB/PKCS1Padding").apply { init(Cipher.DECRYPT_MODE, pair.private) }
        for (value in listOf("", "שלום 😀\nsearch & punctuation!?", "a".repeat(16))) {
            val client = SonyTextCipher(publicKey)
            val envelope = String(rsa.doFinal(Base64.getDecoder().decode(client.encryptedKey)), Charsets.US_ASCII)
            assertTrue(envelope.matches(Regex("[0-9a-f]{32}:[0-9a-f]{32}")))
            val parts = envelope.split(':').map { hex -> hex.chunked(2).map { it.toInt(16).toByte() }.toByteArray() }
            val aes = Cipher.getInstance("AES/CBC/PKCS5Padding").apply {
                init(Cipher.DECRYPT_MODE, SecretKeySpec(parts[0], "AES"), IvParameterSpec(parts[1]))
            }
            assertEquals(value, String(aes.doFinal(Base64.getDecoder().decode(client.encrypt(value))), Charsets.UTF_8))
            try { client.encrypt("second request"); fail("IV reused") } catch (_: IllegalStateException) { }
            client.close()
            try { client.encrypt("after close"); fail("closed secret reused") } catch (_: IllegalStateException) { }
        }
        SonyTextCipher(publicKey).use { first -> SonyTextCipher(publicKey).use { second ->
            val firstEnvelope = rsa.doFinal(Base64.getDecoder().decode(first.encryptedKey))
            val secondEnvelope = rsa.doFinal(Base64.getDecoder().decode(second.encryptedKey))
            assertFalse(firstEnvelope.contentEquals(secondEnvelope))
            assertNotEquals(first.encrypt("same repeated prefix"), second.encrypt("same repeated prefix"))
        } }
    }
}
