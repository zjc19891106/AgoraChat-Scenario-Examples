package io.agora.e3kitdemo.utils

import android.os.Handler
import android.os.Looper
import android.os.Process
import java.util.concurrent.*

/**
 * Thread manager
 */
class ThreadManager private constructor() {
    private var mIOThreadExecutor: Executor? = null
    private var mMainThreadHandler: Handler? = null
    private fun init() {
        val NUMBER_OF_CORES = Runtime.getRuntime().availableProcessors()
        val KEEP_ALIVE_TIME = 1L
        val KEEP_ALIVE_TIME_UNIT = TimeUnit.SECONDS
        val taskQueue: BlockingQueue<Runnable> = LinkedBlockingDeque()
        mIOThreadExecutor = ThreadPoolExecutor(
            NUMBER_OF_CORES,
            NUMBER_OF_CORES * 2,
            KEEP_ALIVE_TIME,
            KEEP_ALIVE_TIME_UNIT,
            taskQueue,
            BackgroundThreadFactory(Process.THREAD_PRIORITY_BACKGROUND)
        )
        mMainThreadHandler = Handler(Looper.getMainLooper())
    }

    /**
     * Switch to an asynchronous thread
     * @param runnable
     */
    fun runOnIOThread(runnable: Runnable?) {
        mIOThreadExecutor!!.execute(runnable)
    }

    /**
     * Switch to the UI thread
     * @param runnable
     */
    fun runOnMainThread(runnable: Runnable?) {
        mMainThreadHandler!!.post(runnable)
    }

    /**
     * Determine if it is the main thread
     * @return true is main thread
     */
    val isMainThread: Boolean
        get() = Looper.getMainLooper().thread === Thread.currentThread()

    companion object {
        @JvmStatic
        @Volatile
        var instance: ThreadManager? = null
            get() {
                if (field == null) {
                    synchronized(ThreadManager::class.java) {
                        if (field == null) {
                            field = ThreadManager()
                        }
                    }
                }
                return field
            }
            private set
    }

    init {
        init()
    }
}