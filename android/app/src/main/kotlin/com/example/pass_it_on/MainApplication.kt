package com.example.pass_it_on

import android.app.Application
import sh.measure.android.Measure
import sh.measure.android.config.MeasureConfig

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Measure.init(this, MeasureConfig())
    }
}
