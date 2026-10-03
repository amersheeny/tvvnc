package dev.tvvnc.tv_vnc.core

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import io.github.ddagunts.screencast.androidtv.NativeRemoteSession
import kotlinx.coroutines.*
import java.util.concurrent.atomic.AtomicLong

class VoiceCapture(private val permissions: Permissions, private val status: (String, String?) -> Unit) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val generation = AtomicLong()
    private val audioLock = Any()
    private var record: AudioRecord? = null
    @Volatile private var stopping = false
    @Volatile private var discard = false
    private var job: Job? = null

    fun start(session: NativeRemoteSession) {
        if (!session.state.value.connected) throw LocalRequestError("not_connected")
        if (session.state.value.features and NativeRemoteSession.VOICE == 0) throw LocalRequestError("unsupported")
        if (job?.isActive == true) return
        val epoch = generation.incrementAndGet()
        stopping = false; discard = false
        job = scope.launch {
            var recorder: AudioRecord? = null
            val samples = ShortArray(4096)
            val output = ByteArray(8192)
            var offset = 0
            var voiceId: Int? = null
            var failure: String? = null
            try {
                // Permission is setup, not consent to begin a new recording.
                if (!permissions.microphoneAllowed()) {
                    val granted = permissions.microphone()
                    if (epoch == generation.get()) status("idle", if (granted) "microphone_ready" else "microphone_permission")
                    return@launch
                }
                ensureActive()
                if (stopping || epoch != generation.get()) return@launch
                status("starting", null)
                voiceId = session.beginVoice()
                ensureActive()
                if (stopping || epoch != generation.get()) return@launch
                val rate = listOf(8000, 16000, 48000).firstOrNull {
                    AudioRecord.getMinBufferSize(it, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT) > 0
                } ?: throw LocalRequestError("microphone_unavailable")
                val bufferSize = maxOf(8192, AudioRecord.getMinBufferSize(rate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT))
                recorder = AudioRecord(MediaRecorder.AudioSource.VOICE_RECOGNITION, rate,
                    AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufferSize)
                if (recorder.state != AudioRecord.STATE_INITIALIZED) throw LocalRequestError("microphone_unavailable")
                synchronized(audioLock) {
                    if (stopping) return@synchronized
                    record = recorder; recorder.startRecording()
                }
                if (stopping) return@launch
                status("listening", null)
                val ratio = rate / 8000
                var sum = 0
                var count = 0
                while (isActive && !stopping && epoch == generation.get()) {
                    val read = recorder.read(samples, 0, samples.size, AudioRecord.READ_BLOCKING)
                    if (read <= 0) {
                        if (stopping) break
                        throw LocalRequestError("microphone_unavailable")
                    }
                    if (Build.VERSION.SDK_INT >= 29 && recorder.activeRecordingConfiguration?.isClientSilenced == true)
                        throw LocalRequestError("microphone_permission")
                    for (i in 0 until read) {
                        sum += samples[i].toInt(); count++
                        if (count == ratio) {
                            val value = (sum / ratio).toShort().toInt()
                            output[offset++] = (value and 255).toByte()
                            output[offset++] = ((value ushr 8) and 255).toByte()
                            sum = 0; count = 0
                            if (offset == output.size) {
                                if (!discard) session.voice(output, voiceId)
                                output.fill(0); offset = 0
                            }
                        }
                    }
                }
            } catch (_: CancellationException) {
                // Release before readiness or lifecycle cancellation, not failure.
            } catch (e: Exception) {
                if (!stopping) failure = if (e is LocalRequestError) e.code else "voice_not_ready"
            } finally {
                synchronized(audioLock) {
                    recorder?.let { r ->
                        try { if (r.recordingState == AudioRecord.RECORDSTATE_RECORDING) r.stop() }
                        catch (_: IllegalStateException) { failure = failure ?: "microphone_unavailable" }
                        finally { r.release() }
                    }
                    if (record === recorder) record = null
                }
                withContext(NonCancellable) {
                    try {
                        if (!discard && failure == null && offset > 0 && voiceId != null && session.state.value.connected) {
                            java.util.Arrays.fill(output, offset, output.size, 0.toByte())
                            session.voice(output, voiceId)
                        }
                        session.endVoice()
                    } catch (_: Exception) { failure = failure ?: "voice_disconnected" }
                }
                samples.fill(0); output.fill(0)
                if (epoch == generation.get() && (voiceId != null || failure != null)) status("idle", failure)
            }
        }
    }
    fun stop(discardAudio: Boolean = false) {
        stopping = true; discard = discardAudio
        var captureStarted = false
        synchronized(audioLock) {
            record?.let {
                captureStarted = true
                try { if (it.recordingState == AudioRecord.RECORDSTATE_RECORDING) it.stop() }
                catch (_: IllegalStateException) { status("idle", "microphone_unavailable") }
            }
        }
        if (!captureStarted || discardAudio) job?.cancel()
        status("idle", null)
    }
    suspend fun dispose() {
        stop(discardAudio = true)
        scope.coroutineContext[Job]?.cancelAndJoin()
    }
}
