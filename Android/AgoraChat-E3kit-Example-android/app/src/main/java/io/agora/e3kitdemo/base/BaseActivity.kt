package io.agora.e3kitdemo.base

import android.os.Bundle
import android.view.MotionEvent
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.ProgressBar
import androidx.appcompat.app.AppCompatActivity

/**
 * As a basic activity, place some public methods
 */
open class BaseActivity : AppCompatActivity() {
    var mContext: BaseActivity? = null
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        mContext = this

        clearFragmentsBeforeCreate()
    }

    override fun onBackPressed() {
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        if (window.attributes.softInputMode != WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN) {
            if (currentFocus != null) {
                imm.hideSoftInputFromWindow(
                    currentFocus!!.windowToken,
                    InputMethodManager.HIDE_NOT_ALWAYS
                )
                super.onBackPressed()
            } else {
                super.onBackPressed()
            }
        } else {
            super.onBackPressed()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    /**
     * hide keyboard
     */
    fun hideKeyboard() {
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        if (window.attributes.softInputMode != WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN) {
            if (currentFocus != null) {
                imm.hideSoftInputFromWindow(
                    currentFocus!!.windowToken,
                    InputMethodManager.HIDE_NOT_ALWAYS
                )
            }
        }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (null != this.currentFocus) {
            /**
             * Click on the blank position to hide the soft keyboard
             */
            val mInputMethodManager = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
            return mInputMethodManager.hideSoftInputFromWindow(this.currentFocus!!.windowToken, 0)
        }
        return super.onTouchEvent(event)
    }

    /**
     * Deal with the fragment overlay problem caused by Activity reconstruction
     */
    private fun clearFragmentsBeforeCreate() {
        val fragments = supportFragmentManager.fragments
        if (fragments.size == 0) {
            return
        }
        val fragmentTransaction = supportFragmentManager.beginTransaction()
        for (fragment in fragments) {
            fragmentTransaction.remove(fragment!!)
        }
        fragmentTransaction.commitNow()
    }
}