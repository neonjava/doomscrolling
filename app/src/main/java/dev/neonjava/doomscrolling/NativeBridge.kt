package dev.neonjava.doomscrolling

/** The only entry point into the Rust library. Android objects never cross this boundary. */
object NativeBridge {
    val available: Boolean = runCatching {
        System.loadLibrary("doomscrolling_core")
        protocolVersion() == 1
    }.getOrDefault(false)
    external fun protocolVersion(): Int
    external fun evaluate(snapshot: String): String?
    external fun touch(action: Int, x: Float, y: Float, time: Long, slop: Float): Int
    external fun reset()
}
