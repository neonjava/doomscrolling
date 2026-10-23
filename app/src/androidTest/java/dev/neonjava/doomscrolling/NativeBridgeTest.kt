package dev.neonjava.doomscrolling

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith

/** Runs inside Android's VM: verifies packaging, native symbol lookup and the actual JNI boundary. */
@RunWith(AndroidJUnit4::class)
class NativeBridgeTest {
    @After fun tearDown() { NativeBridge.reset() }
    @Test fun testNativeLibraryLoads() {
        assertTrue(NativeBridge.available)
        assertEquals(1, NativeBridge.protocolVersion())
    }
    @Test fun testMalformedSnapshotDisablesInterception() {
        assertTrue(NativeBridge.evaluate("not JSON")!!.contains("\"active\":false"))
        assertEquals(0, NativeBridge.touch(0, 100f, 100f, 0, 12f))
        assertEquals(0, NativeBridge.touch(1, 100f, 100f, 50, 12f))
    }
    @Test fun testViewerTapSwipeAndTeardownAcrossJni() {
        val snapshot = """{"package":"com.google.android.youtube","enabled":true,"youtube":true,"instagram":true,"width":1080,"height":2400,"nodes":[{"id":"com.google.android.youtube:id/reel_watch_fragment_root","bounds":{"left":0,"top":126,"right":1080,"bottom":2196}},{"id":"com.google.android.youtube:id/reel_player_page_content","bounds":{"left":0,"top":126,"right":1080,"bottom":2196}}]}"""
        assertTrue(NativeBridge.evaluate(snapshot)!!.contains("\"active\":true"))
        NativeBridge.touch(0, 100f, 500f, 0, 12f)
        assertEquals(1, NativeBridge.touch(1, 100f, 500f, 50, 12f))
        NativeBridge.touch(0, 100f, 500f, 100, 12f)
        assertEquals(2, NativeBridge.touch(1, 100f, 100f, 150, 12f))
        NativeBridge.reset()
        assertEquals(0, NativeBridge.touch(1, 100f, 500f, 200, 12f))
    }
}
