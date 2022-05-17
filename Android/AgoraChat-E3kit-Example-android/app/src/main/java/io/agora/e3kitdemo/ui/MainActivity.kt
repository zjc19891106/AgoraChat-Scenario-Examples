package io.agora.e3kitdemo.ui

import android.content.Intent
import android.os.Bundle
import android.view.MotionEvent
import android.view.View
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.virgilsecurity.android.common.model.Group
import io.agora.CallBack
import io.agora.chat.ChatClient
import io.agora.e3kitdemo.DemoHelper
import io.agora.e3kitdemo.R
import io.agora.e3kitdemo.base.BaseActivity
import io.agora.e3kitdemo.databinding.ActivityMainBinding
import io.agora.e3kitdemo.utils.ResultCallBack
import io.agora.e3kitdemo.utils.ThreadManager
import kotlinx.android.synthetic.main.activity_login.*


class MainActivity : BaseActivity() {
    private lateinit var binding: ActivityMainBinding
    private var isLogin: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        val view = binding.root
        setContentView(view)
        initData()
        initListener();
    }

    private fun initData() {
    }

    override fun onResume() {
        super.onResume()
        updateView()
    }

    private fun updateView() {
        if (ChatClient.getInstance().isLoggedInBefore) {
            if (isLogin) {
                return
            }
            isLogin = true
            val username = ChatClient.getInstance().currentUser
            if (!username.isNullOrEmpty()) {
                binding.loginUserInfo.text = this.getString(R.string.login_user_info, username)
                enableView(binding.login, false)
                enableView(binding.logout, true)
                enableView(binding.chats, true)
                ThreadManager.instance?.runOnIOThread(kotlinx.coroutines.Runnable {
                    binding.loading.visibility = View.VISIBLE
                    DemoHelper.demoHelper.initEThree(
                        username,
                        mContext!!.applicationContext
                    ) {
                        runOnUiThread {
                            binding.loading.visibility = View.GONE
                        }
                    }
                })
                return
            }
        }
        binding.loginUserInfo.text = this.getString(R.string.login_none)
        enableView(binding.login, true)
        enableView(binding.logout, false)
        enableView(binding.chats, false)
        isLogin = false
    }

    private fun enableView(view: TextView, enable: Boolean) {
        view.isEnabled = enable
        if (enable) {
            view.setTextColor(ContextCompat.getColor(this@MainActivity, R.color.black))
        } else {
            view.setTextColor(ContextCompat.getColor(this@MainActivity, R.color.gray))
        }
    }

    private fun initListener() {
        binding.login.setOnClickListener {
            val intent = Intent(this, LoginActivity::class.java)
            startActivity(intent)
        }

        binding.loginEnterIcon.setOnClickListener {
            val intent = Intent(this, LoginActivity::class.java)
            startActivity(intent)
        }

        Group
        binding.logout.setOnClickListener {
            binding.loading.visibility = View.VISIBLE
            logout(true, object : ResultCallBack<Boolean>() {
                override fun onError(error: Int, errorMsg: String?) {
                    runOnUiThread {
                        binding.loading.visibility = View.GONE
                        btn_login.isEnabled = true
                    }
                }

                override fun onSuccess(value: Boolean?) {
                    ThreadManager.instance?.runOnIOThread(kotlinx.coroutines.Runnable {
                        DemoHelper.demoHelper.logout()
                    })
                    runOnUiThread {
                        binding.loading.visibility = View.GONE
                        updateView()
                    }

                }

            })
        }

        binding.chats.setOnClickListener {
            val intent = Intent(this, ConversationActivity::class.java)
            startActivity(intent)

        }

        binding.chatsEnterIcon.setOnClickListener {
            val intent = Intent(this, ConversationActivity::class.java)
            startActivity(intent)
        }

        binding.loading.setOnTouchListener { v, event -> true }
    }

    private fun logout(unbindDeviceToken: Boolean, callBack: ResultCallBack<Boolean>) {
        ThreadManager.instance!!.runOnIOThread(Runnable {
            ChatClient.getInstance().logout(unbindDeviceToken,
                object : CallBack {
                    override fun onSuccess() {
                        callBack.onSuccess(true)
                    }

                    override fun onProgress(progress: Int, status: String) {}
                    override fun onError(code: Int, error: String) {
                        callBack.onError(code, error)
                    }
                })
        })

    }

}
