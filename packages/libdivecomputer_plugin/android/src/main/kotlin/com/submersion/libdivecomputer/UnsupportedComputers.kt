// DiveDown: new file (ui-spec §5.6, T12.7). GPL-3.0-or-later.

package com.submersion.libdivecomputer

/**
 * Dive computers libdivecomputer cannot read, reported with model -1 so the
 * app can point to the FIT import. A fixed list: other unmatched devices are
 * never passed on (security.md A4). Mirrored in darwin BleScanner.swift.
 */
object UnsupportedComputers {
    const val MODEL = -1L

    data class Match(val vendor: String, val product: String)

    private val products = listOf("Ocean", "Nautic")

    fun match(advertisedName: String): Match? {
        val name = advertisedName.trim().lowercase()
        for (product in products) {
            val p = product.lowercase()
            if (name == p || name == "suunto $p" || name.startsWith("suunto $p ")) {
                return Match("Suunto", product)
            }
        }
        return null
    }
}
