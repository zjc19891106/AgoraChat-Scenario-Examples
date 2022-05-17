package io.agora.e3kitdemo.ui

import android.os.Bundle
import android.os.StrictMode
import android.text.method.ScrollingMovementMethod
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.virgilsecurity.android.common.model.FindUsersResult
import io.agora.e3kitdemo.R
import io.agora.e3kitdemo.e3kit.Device


var log: ((String) -> Unit) = {};

class DemoActivity : AppCompatActivity() {

    lateinit var alice: Device
    lateinit var bob: Device

    lateinit var bobUsers: FindUsersResult
    lateinit var aliceUsers: FindUsersResult

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_demo)

        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
        StrictMode.setThreadPolicy(policy)

        findViewById<TextView>(R.id.textView).movementMethod = ScrollingMovementMethod()

        fun logTextView(log: String) {
            this.runOnUiThread {
                val view = findViewById<TextView>(R.id.textView)
                val text = view.text.toString()
                view.text = "$text\n$log"
            }
        }

        log = ::logTextView

        alice = Device("11111", this.applicationContext)
        bob = Device("22222", this.applicationContext)

        main()
    }

    fun main() {
        log("* Testing main methods:")

        log("\n----- Initialize EThree -----")
        initializeUsers {
            log("\n----- EThree.register -----")
            registerUsers {
                log("\n----- EThree.findUsers -----")
                lookupPublicKeys {
                    log("\n----- EThree.authEncrypt & EThree.authDecrypt -----")
                    encryptAndDecrypt {

                    }
                }
            }
        }
    }

    fun initializeUsers(callback: () -> Unit) {
        alice.initialize {
            bob.initialize(callback)
        }
    }

    fun registerUsers(callback: () -> Unit) {
        alice.register {
            bob.register(callback)
        }
    }

    fun lookupPublicKeys(callback: () -> Unit) {
        alice.findUsers(listOf(bob.identity)) { bobResult ->
            if (null != bobResult) {
                bobUsers = bobResult
            }
            bob.findUsers(listOf(alice.identity)) { aliceResult ->
                if (null != aliceResult) {
                    aliceUsers = aliceResult
                }
                callback()
            }
        }
    }

    fun encryptAndDecrypt(callback: () -> Unit) {
        val aliceEncryptedText = alice.encrypt("Hello ${bob.identity}!", bobUsers)
        bob.decrypt(aliceEncryptedText, aliceUsers[alice.identity]!!)

        val bobEncryptedText = bob.encrypt("Hello ${alice.identity}!", aliceUsers)
        alice.decrypt(bobEncryptedText, bobUsers[bob.identity]!!)
    }


}
