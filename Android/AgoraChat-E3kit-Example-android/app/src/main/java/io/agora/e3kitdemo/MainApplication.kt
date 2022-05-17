package io.agora.e3kitdemo;

import android.app.Application


class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        DemoHelper.demoHelper.initAgoraSdk(this.applicationContext)
    }
}
