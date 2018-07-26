package com.tobykurien.webmediashare.utils

import com.tobykurien.webmediashare.BuildConfig

/**
 * Global debug switches for testing and debugging
 */
class Debug {
    public val static boolean ON = BuildConfig.DEBUG // global on/off switch. Turn off for production

    public val static boolean FAVICON = ON && false // spit out debug info for favicon handling
    public val static boolean COOKIE = ON && false // spit out debug info for cookie handling
}