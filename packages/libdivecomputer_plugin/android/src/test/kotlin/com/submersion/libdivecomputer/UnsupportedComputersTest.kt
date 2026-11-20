// DiveDown: new file (ui-spec §5.6, T12.7). GPL-3.0-or-later.

package com.submersion.libdivecomputer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

// Dive computers libdivecomputer cannot read but the app should show greyed
// out with a hint to the FIT import. Only names on this list are reported;
// other unmatched devices stay invisible (security.md A4).
class UnsupportedComputersTest {

    @Test
    fun suuntoOceanAndNauticAreRecognised() {
        assertEquals("Ocean", UnsupportedComputers.match("Suunto Ocean")?.product)
        assertEquals("Suunto", UnsupportedComputers.match("suunto ocean 1234")?.vendor)
        assertEquals("Nautic", UnsupportedComputers.match("Suunto Nautic S")?.product)
        assertEquals("Ocean", UnsupportedComputers.match(" Ocean ")?.product)
    }

    @Test
    fun otherDevicesAreNotReported() {
        assertNull(UnsupportedComputers.match("Annas AirPods"))
        assertNull(UnsupportedComputers.match("Ocean Speaker"))
        assertNull(UnsupportedComputers.match("EON Core"))
    }
}
