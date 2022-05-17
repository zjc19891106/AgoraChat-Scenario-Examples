package io.agora.e3kitdemo.utils

import android.os.Process
import java.util.concurrent.ThreadFactory

/**
 * the factory to use when the executor creates a new thread
 */
class BackgroundThreadFactory(private val mThreadPriority: Int) : ThreadFactory {
    override fun newThread(runnable: Runnable): Thread {
        val wrapperRunnable = Runnable {
            try {
                Process.setThreadPriority(mThreadPriority)
            } catch (e: Throwable) {
                e.printStackTrace()
            }
            runnable.run()
        }
        return Thread(wrapperRunnable)
    }
}