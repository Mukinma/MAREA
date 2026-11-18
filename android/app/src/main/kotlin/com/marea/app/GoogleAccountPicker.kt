package com.marea.app

import android.app.Activity
import android.os.CancellationSignal
import androidx.core.content.ContextCompat
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialProviderConfigurationException
import androidx.credentials.exceptions.GetCredentialUnsupportedException
import androidx.credentials.exceptions.NoCredentialException
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

internal class GoogleAccountPicker(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "marea/google-sign-in")
    private var pending: Pair<CancellationSignal, MethodChannel.Result>? = null

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "chooseAccount") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val clientId = call.argument<String>("serverClientId")
            val nonce = call.argument<String>("nonce")
            if (clientId.isNullOrBlank() || nonce.isNullOrBlank() || pending != null) {
                result.error("google_picker_failed", null, null)
                return@setMethodCallHandler
            }
            chooseAccount(clientId, nonce, result)
        }
    }

    private fun chooseAccount(clientId: String, nonce: String, result: MethodChannel.Result) {
        val hashedNonce = MessageDigest.getInstance("SHA-256")
            .digest(nonce.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
        val option = GetSignInWithGoogleOption.Builder(clientId).setNonce(hashedNonce).build()
        val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
        val signal = CancellationSignal()
        pending = signal to result
        CredentialManager.create(activity).getCredentialAsync(
            activity, request, signal, ContextCompat.getMainExecutor(activity),
            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                override fun onResult(response: GetCredentialResponse) {
                    if (pending?.first !== signal) return
                    pending = null
                    val credential = response.credential as? CustomCredential
                    if (credential?.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                        try {
                            result.success(GoogleIdTokenCredential.createFrom(credential.data).idToken)
                        } catch (_: GoogleIdTokenParsingException) {
                            result.error("google_picker_failed", null, null)
                        }
                    } else {
                        result.error("google_picker_failed", null, null)
                    }
                }

                override fun onError(error: GetCredentialException) {
                    if (pending?.first !== signal) return
                    pending = null
                    when (error) {
                        is GetCredentialCancellationException -> result.success(null)
                        is NoCredentialException,
                        is GetCredentialProviderConfigurationException,
                        is GetCredentialUnsupportedException -> result.error("unavailable", null, null)
                        else -> result.error("google_picker_failed", null, null)
                    }
                }
            },
        )
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        val request = pending ?: return
        pending = null
        request.first.cancel()
        request.second.success(null)
    }
}
