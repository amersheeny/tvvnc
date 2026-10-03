package dev.tvvnc.tv_vnc.core

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.view.Surface
import dev.tvvnc.tv_vnc.bridge.ScreenInfo
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.*
import java.util.concurrent.atomic.AtomicLong

/** One instance per RFB connection. Old callbacks cannot reach a newer session. */
class VncBridge(private val context: Context, private val textures: TextureRegistry,
    private val onChange: (ScreenInfo) -> Unit) : ScreenSource {
    private val main = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val epoch = AtomicLong(nextEpoch.incrementAndGet())
    @Volatile private var handle = 0L
    val connectionId: Long get() = handle
    private val ownership = Any()
    @Volatile private var closed = false
    private var producer: TextureRegistry.SurfaceProducer? = null
    @Volatile private var surfaceAvailable = false
    @Volatile override var state = ScreenInfo(null, 0, 0, epoch.get(), 0, false, true, null); private set
    private var lastPublished = 0L

    suspend fun start(host: String, port: Int, password: String): ScreenInfo {
        val address = PrivateNetwork.resolve(host)
        show()
        withContext(Dispatchers.IO) {
            val bytes = password.toByteArray(Charsets.UTF_8)
            try {
                val created = nativeStart(address, port, bytes)
                val keep = synchronized(ownership) { if (closed) false else { handle = created; true } }
                if (!keep && created != 0L) nativeStop(created)
            } finally { bytes.fill(0) }
        }
        withContext(Dispatchers.Main) { if (!closed) { nativeInputEpoch(handle, epoch.get()); nativeSurface(handle, producer!!.surface) } }
        return state
    }

    override suspend fun show(): ScreenInfo = withContext(Dispatchers.Main) {
        if (producer == null && !closed) {
            producer = textures.createSurfaceProducer().also { surface ->
                surface.setSize(state.width.toInt().coerceAtLeast(1), state.height.toInt().coerceAtLeast(1))
                surface.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                    override fun onSurfaceAvailable() {
                        surfaceAvailable = true
                        if (!closed && handle != 0L) {
                            nativeSurface(handle, surface.surface)
                            scope.launch { refresh() }
                        }
                    }
                    override fun onSurfaceCleanup() {
                        surfaceAvailable = false
                        if (handle != 0L) nativeSurface(handle, null)
                        epoch.set(nextEpoch.incrementAndGet())
                        nativeInputEpoch(handle, epoch.get())
                        state = state.copy(stale = true, generation = epoch.get())
                        onChange(state)
                    }
                })
            }
            surfaceAvailable = true
            state = state.copy(textureId = producer!!.id(), hidden = false)
            if (handle != 0L) {
                nativeSurface(handle, producer!!.surface)
                scope.launch { refresh() }
            }
            onChange(state)
        }
        state
    }
    override suspend fun hide() = withContext(Dispatchers.Main) {
        surfaceAvailable = false
        if (handle != 0L) nativeSurface(handle, null)
        producer?.release(); producer = null
        epoch.set(nextEpoch.incrementAndGet())
        nativeInputEpoch(handle, epoch.get())
        state = state.copy(textureId = null, stale = true, generation = epoch.get(), hidden = true)
        onChange(state)
    }

    @Suppress("unused")
    private fun onNativeMetadata(name: ByteArray, major: Int, minor: Int, security: Int, extended: Boolean) {
        main.post {
            if (!closed) {
                state = state.copy(desktopName = name.toString(Charsets.UTF_8).filterNot { it.isISOControl() },
                    protocolVersion = "$major.$minor", securityType = security.toLong(), extendedClipboard = extended)
                onChange(state)
            }
        }
    }
    @Suppress("unused")
    private fun onNativeEvent(kind: Int, a: Int, b: Int) {
        main.post {
            if (closed) return@post
            when (kind) {
                1 -> {
                    epoch.set(nextEpoch.incrementAndGet())
                    nativeInputEpoch(handle, epoch.get())
                    state = state.copy(width = a.toLong(), height = b.toLong(), stale = true,
                        generation = epoch.get())
                    producer?.setSize(a, b)
                    if (handle != 0L) nativeSurface(handle, producer?.surface)
                }
                2 -> state = state.copy(width = a.toLong(), height = b.toLong(),
                    connected = true, stale = !surfaceAvailable, frameAt = System.currentTimeMillis(), errorCode = null)
                3 -> state = state.copy(connected = true, errorCode = null)
                5 -> state = state.copy(connected = true, stale = true, frameAt = System.currentTimeMillis(),
                    errorCode = if (surfaceAvailable) "surface_unavailable" else null)
                4 -> {
                    epoch.set(nextEpoch.incrementAndGet())
                    state = state.copy(connected = false, stale = true,
                    generation = epoch.get(), errorCode = when (a) {
                        2 -> "authentication_required"; 3 -> "invalid_frame"; 4 -> "frame_too_large"
                        5 -> "surface_unavailable"; 6 -> "timeout"; 7 -> "network_permission"; else -> "connection_failed"
                    })
                }
            }
            val now = System.currentTimeMillis()
            if ((kind != 2 && kind != 5) || now - lastPublished >= 200) { lastPublished = now; onChange(state) }
        }
    }
    suspend fun pointer(x: Int, y: Int, buttons: Int, generation: Long): Int = withContext(Dispatchers.IO) {
        val frame = state
        if (closed || frame.stale || !frame.connected || generation != frame.generation) return@withContext 0
        nativeCommand(handle, 0, x, y, buttons, frame.width.toInt(), frame.height.toInt(), null, generation)
    }
    suspend fun key(keysym: Int, down: Boolean): Int = withContext(Dispatchers.IO) {
        if (closed) 0 else nativeCommand(handle, 1, keysym, if (down) 1 else 0, 0, 0, 0, null)
    }
    suspend fun clipboard(value: String): Int = withContext(Dispatchers.IO) {
        if (closed) return@withContext 0
        val bytes = value.toByteArray(Charsets.UTF_8)
        try { nativeCommand(handle, 2, 0, 0, 0, 0, 0, bytes) } finally { bytes.fill(0) }
    }
    override suspend fun refresh(): Int = withContext(Dispatchers.IO) {
        if (closed) 0 else nativeCommand(handle, 3, 0, 0, 0, 0, 0, null)
    }
    suspend fun detail(fullResolution: Boolean): Int = withContext(Dispatchers.IO) {
        if (closed) 0 else nativeCommand(handle, 4, if (fullResolution) 0 else 1280, 0, 0, 0, 0, null)
    }
    override fun invalidate() {
        main.post {
            if (!closed) {
                epoch.set(nextEpoch.incrementAndGet())
                nativeInputEpoch(handle, epoch.get())
                state = state.copy(stale = true, generation = epoch.get())
                onChange(state)
                scope.launch { refresh() }
            }
        }
    }
    override suspend fun screenshot(): String = withContext(Dispatchers.IO) {
        val observed = state
        if (observed.stale || !observed.connected || closed) throw LocalRequestError("screen_unavailable")
        val bitmap = Bitmap.createBitmap(observed.width.toInt(), observed.height.toInt(), Bitmap.Config.ARGB_8888)
        try {
            // Exactly one snapshot allocation. A resize race is not captured as
            // a wrongly-sized image; report unavailable without saving a file.
            if (!nativeCopyBitmap(handle, bitmap)) throw LocalRequestError("screen_unavailable")
            val filename = "TV-${System.currentTimeMillis()}.png"
            if (Build.VERSION.SDK_INT >= 29) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/TV Console")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
                val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                    ?: throw LocalRequestError("screenshot_failed")
                try {
                    context.contentResolver.openOutputStream(uri)!!.use {
                        if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)) throw LocalRequestError("screenshot_failed")
                    }
                    context.contentResolver.update(uri, ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) }, null, null)
                } catch (e: Exception) { context.contentResolver.delete(uri, null, null); throw e }
                uri.toString()
            } else {
                val directory = context.getExternalFilesDir(android.os.Environment.DIRECTORY_PICTURES) ?: context.filesDir
                val file = java.io.File.createTempFile("TV-", ".png", directory)
                try { file.outputStream().use {
                    if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)) throw LocalRequestError("screenshot_failed")
                } } catch (e: Exception) { file.delete(); throw e }
                file.absolutePath
            }
        } finally { bitmap.recycle() }
    }
    override suspend fun close() = withContext(NonCancellable) {
        val prior = synchronized(ownership) { closed = true; handle.also { handle = 0 } }
        scope.cancel()
        withContext(Dispatchers.IO) {
            if (prior != 0L) {
                // Best effort on this exact old connection, never a replacement.
                nativeCommand(prior, 5, 0, 0, 0, 0, 0, null)
                nativeStop(prior)
            }
        }
        withContext(Dispatchers.Main) {
            producer?.release(); producer = null
            epoch.set(nextEpoch.incrementAndGet())
            state = state.copy(textureId = null, connected = false, stale = true, generation = epoch.get())
            onChange(state)
        }
    }
    private external fun nativeStart(host: String, port: Int, password: ByteArray): Long
    private external fun nativeSurface(handle: Long, surface: Surface?)
    private external fun nativeInputEpoch(handle: Long, generation: Long)
    private external fun nativeCommand(handle: Long, kind: Int, a: Int, b: Int, c: Int,
        width: Int, height: Int, bytes: ByteArray?, generation: Long = 0): Int
    private external fun nativeCopyBitmap(handle: Long, bitmap: Bitmap): Boolean
    private external fun nativeStop(handle: Long)
    companion object {
        private val nextEpoch = AtomicLong()
        init { System.loadLibrary("tvvnc") }
    }
}
