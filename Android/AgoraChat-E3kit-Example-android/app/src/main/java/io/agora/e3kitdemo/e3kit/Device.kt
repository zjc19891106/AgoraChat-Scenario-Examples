package io.agora.e3kitdemo.e3kit;

import android.content.Context
import android.util.Log
import com.virgilsecurity.android.common.exception.EThreeException
import com.virgilsecurity.android.common.model.EThreeParams
import com.virgilsecurity.android.common.model.FindUsersResult
import com.virgilsecurity.android.common.model.Group
import com.virgilsecurity.android.ethree.interaction.EThree
import com.virgilsecurity.common.callback.OnCompleteListener
import com.virgilsecurity.common.callback.OnResultListener
import com.virgilsecurity.sdk.cards.Card
import io.agora.e3kitdemo.BuildConfig
import io.agora.e3kitdemo.Constants
import io.agora.util.EMLog
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import kotlin.system.measureTimeMillis

class Device(val identity: String, private val context: Context) {

    private var eThree: EThree? = null
    private val benchmarking = false

    fun _log(e: String) {
        Log.i("e3kit", e)
    }

    fun initialize(callback: () -> Unit) {

        //# start of snippet: e3kit_authenticate
        fun authenticate(): String {
            val baseUrl = BuildConfig.E3KIT_APP_SERVER + "/authenticate"
            val fullUrl = URL(baseUrl)

            val urlConnection = fullUrl.openConnection() as HttpURLConnection
            urlConnection.doOutput = true
            urlConnection.doInput = true
            urlConnection.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
            urlConnection.setRequestProperty("Accept", "application/json")
            urlConnection.requestMethod = "POST"

            val cred = JSONObject()

            cred.put("identity", identity)

            val wr = urlConnection.outputStream
            wr.write(cred.toString().toByteArray(charset("UTF-8")))
            wr.close()

            val httpResult = urlConnection.responseCode
            if (httpResult == HttpURLConnection.HTTP_OK) {
                val response =
                    InputStreamReader(urlConnection.inputStream, "UTF-8").buffered().use {
                        it.readText()
                    }

                val jsonObject = JSONObject(response)

                return jsonObject.getString("authToken")
            } else {
                throw Throwable("$httpResult")
            }
        }
        //# end of snippet: e3kit_authenticate

        //# start of snippet: e3kit_jwt_callback
        fun getVirgilJwt(authToken: String): String {
            try {
                val baseUrl = BuildConfig.E3KIT_APP_SERVER + "/virgil-jwt"
                val fullUrl = URL(baseUrl)

                val urlConnection = fullUrl.openConnection() as HttpURLConnection
                urlConnection.setRequestProperty("Accept", "application/json")
                urlConnection.setRequestProperty("Authorization", "Bearer $authToken")
                urlConnection.requestMethod = "GET"

                val httpResult = urlConnection.responseCode
                if (httpResult == HttpURLConnection.HTTP_OK) {
                    val response =
                        InputStreamReader(urlConnection.inputStream, "UTF-8").buffered().use {
                            it.readText()
                        }
                    val jsonObject = JSONObject(response)

                    return jsonObject.getString("virgilToken")
                } else {
                    throw RuntimeException("$httpResult $authToken")
                }
            } catch (e: IOException) {
                throw RuntimeException("$e")
            } catch (e: JSONException) {
                throw RuntimeException("$e")
            }
        }
        //# end of snippet: e3kit_jwt_callback

        val authToken = authenticate()

        //# start of snippet: e3kit_initialize
        val eThreeParams = EThreeParams(identity, { getVirgilJwt(authToken) }, context)
        //eThreeParams.keyPairType = KeyPairType.CURVE25519_ROUND5_ED25519_FALCON
        eThree = EThree(eThreeParams)
        _log("Initialized")
        callback()
        //# end of snippet: e3kit_initialize
    }

    private fun getEThreeInstance(): EThree {
        val eThree = eThree

        if (eThree == null) {
            val errorMessage = "eThree not initialized for $identity"
            throw Throwable(errorMessage)
        }

        return eThree
    }

    fun register(callback: () -> Unit) {
        val eThree = getEThreeInstance()

        //# start of snippet: e3kit_register
        eThree.register().addCallback(object : OnCompleteListener {
            override fun onSuccess() {
                _log("Registered")
                callback()
            }

            override fun onError(throwable: Throwable) {
                _log("Failed registering: $throwable")

                if (throwable.message?.contains(
                        "Private key already exists in local key storage",
                        ignoreCase = true
                    ) == true || throwable.message?.contains(
                        "User is already registered",
                        ignoreCase = true
                    ) == true
                ) {
                    _log("${throwable.message}")
                    callback()
                } else {
                    if (throwable is EThreeException) {
                        if (eThree.hasLocalPrivateKey()) {
                            _log("cleanup")
                            eThree.cleanup()
                        }
                        eThree.rotatePrivateKey().addCallback(object : OnCompleteListener {
                            override fun onSuccess() {
                                _log("Rotated private key instead")
                                callback()
                            }

                            override fun onError(throwable: Throwable) {
                                _log("Failed rotatePrivateKey: $throwable")
                            }
                        })
                    }
                }
            }
        })
        //# end of snippet: e3kit_register
    }

    fun findUsers(identities: List<String>, callback: (FindUsersResult?) -> Unit) {
        val eThree = getEThreeInstance()
        //# start of snippet: e3kit_lookup_public_keys
        eThree.findUsers(identities).addCallback(object : OnResultListener<FindUsersResult> {
            override fun onError(throwable: Throwable) {
                _log("Failed finding user $identities: $throwable")
                callback(null)
            }

            override fun onSuccess(result: FindUsersResult) {
                _log("Found user $identities")
                callback(result)
            }

        })
        //# end of snippet: e3kit_lookup_public_keys
    }

    fun encrypt(text: String, findUsersResult: FindUsersResult): String {
        val eThree = getEThreeInstance()
        var encryptedText = ""
        var time: Long = 0

        try {
            val repetitions = if (benchmarking) 100 else 1
            for (i in 1..repetitions) {
                time += measureTimeMillis {
                    //# start of snippet: e3kit_encrypt
                    encryptedText = eThree.authEncrypt(text, findUsersResult)
                    //# end of snippet: e3kit_encrypt
                }
            }

            _log("Encrypted and signed: '$encryptedText'. Took: ${time / repetitions}ms")
        } catch (e: Throwable) {
            _log("Failed encrypting and signing: $e")
        }

        return encryptedText
    }

    fun decrypt(text: String, senderCard: Card): String {
        val eThree = getEThreeInstance()
        var decryptedText = ""
        var time: Long = 0

        try {
            val repetitions = if (benchmarking) 100 else 1
            for (i in 1..repetitions) {
                time += measureTimeMillis {
                    //# start of snippet: e3kit_decrypt
                    decryptedText = eThree.authDecrypt(text, senderCard)
                    //# end of snippet: e3kit_decrypt
                }

            }
            _log("Decrypted and verified: $decryptedText. Took: ${time / repetitions}ms")
        } catch (e: Throwable) {
            _log("Failed decrypting and verifying: $e")
        }

        return decryptedText
    }

    fun logout() {
        _log("logout")
    }

    fun createGroup(groupId: String, identities: List<String>, callback: (Group?) -> Unit) {
        findUsers(identities) { userResult ->
            if (null != userResult) {
                val group = getEThreeInstance().createGroup(groupId, userResult).get()
                callback(group)
            } else {
                callback(null)
            }
        }
    }

    fun loadGroup(groupId: String, groupInitiator: String, callback: (Group?) -> Unit) {
        findUsers(listOf(groupInitiator)) { userResult ->
            if (null == userResult) {
                callback(null)
            } else {
                EMLog.i(Constants.TAG, "find user:${userResult[groupInitiator]}")
                val group =
                    getEThreeInstance().loadGroup(groupId, userResult[groupInitiator]!!).get()
                EMLog.i(Constants.TAG, "load group:${group}")
                callback(group)
            }
        }
    }
}
