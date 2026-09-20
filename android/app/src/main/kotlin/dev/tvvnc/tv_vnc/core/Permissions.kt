package dev.tvvnc.tv_vnc.core

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import kotlinx.coroutines.*

class Permissions(private val activity: Activity) {
    private val requests = mutableMapOf<Int, Pair<String, CompletableDeferred<Boolean>>>()
    private val pending = mutableMapOf<String, CompletableDeferred<Boolean>>()
    private var nextRequest = 8100
    @Volatile private var android16Restricted = false
    fun noteNetworkDenial() { if (Build.VERSION.SDK_INT == 36) android16Restricted = true }
    fun networkAllowed() = when {
        Build.VERSION.SDK_INT >= 37 -> activity.checkSelfPermission("android.permission.ACCESS_LOCAL_NETWORK") == PackageManager.PERMISSION_GRANTED
        Build.VERSION.SDK_INT == 36 && android16Restricted -> activity.checkSelfPermission(Manifest.permission.NEARBY_WIFI_DEVICES) == PackageManager.PERMISSION_GRANTED
        else -> true
    }
    suspend fun network(): Boolean {
        val permission = when {
            Build.VERSION.SDK_INT >= 37 -> "android.permission.ACCESS_LOCAL_NETWORK"
            Build.VERSION.SDK_INT == 36 && android16Restricted -> Manifest.permission.NEARBY_WIFI_DEVICES
            else -> return true
        }
        return request(permission)
    }
    suspend fun microphone() = request(Manifest.permission.RECORD_AUDIO)
    fun microphoneAllowed() = activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    private suspend fun request(permission: String): Boolean = withContext(Dispatchers.Main) {
        if (activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) return@withContext true
        pending[permission]?.let { return@withContext it.await() }
        val result = CompletableDeferred<Boolean>()
        val id = nextRequest++
        pending[permission] = result; requests[id] = permission to result
        // A caller ending its gesture must not erase an OS permission request
        // that is still on screen. Later callers share its result, not a second dialog.
        try { activity.requestPermissions(arrayOf(permission), id) }
        catch (e: Exception) { pending.remove(permission); requests.remove(id); result.completeExceptionally(e) }
        result.await()
    }
    fun result(code: Int, grants: IntArray) {
        requests.remove(code)?.let { (permission, result) ->
            pending.remove(permission)
            result.complete(grants.isNotEmpty() && grants.all { p -> p == PackageManager.PERMISSION_GRANTED })
        }
    }
    fun openSettings() = activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}")))
    fun close() { requests.values.toList().forEach { it.second.cancel() }; requests.clear(); pending.clear() }
}
