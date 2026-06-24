# SPDX-License-Identifier: Apache-2.0

# Suppress "unique_unit_address_if_enabled" to handle known nRF52810 SoC overlaps:
# - power@40000000 & clock@40000000 & bprot@40000000
#
# These are known hardware overlaps in the nRF52810 SoC. The clock, power, and
# bprot peripherals genuinely share the same base address (0x40000000) on the
# nRF52810 silicon — this is not a bug in the board DTS.
#
# The upstream nrf52dk board suppresses these warnings in the same way via its
# own pre_dt_board.cmake. Every Nordic board using the nRF52810 SoC requires
# this suppression because the hardware itself maps those three peripherals to
# the same base address.
list(APPEND EXTRA_DTC_FLAGS "-Wno-unique_unit_address_if_enabled")
