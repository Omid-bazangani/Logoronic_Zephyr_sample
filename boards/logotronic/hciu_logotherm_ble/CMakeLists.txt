# SPDX-License-Identifier: Apache-2.0

# The nrf52810 silicon mirrors the nRF52832 DK hardware.
# These definitions are required by certain system initialization routines.
zephyr_compile_definitions(DEVELOP_IN_NRF52832)
zephyr_compile_definitions(NRFX_COREDEP_DELAY_US_LOOP_CYCLES=3)
