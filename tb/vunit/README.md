# vunit test benches

## Conventions from vunit
 * All tb_*.vhd and *_tb.vhd files in the subdirectories will be run against
   vunit.
 * All *.vhd files in the subdirectories containing the runner_cfg generic in the
   top entity will be run against vunit.

## Conventions for this directory
 * Files in the ../../hdl subdirectories are compiled and available for vunit
 * Entities ending with _tbc will be tested with and without a clock, see the
   example : [00_test_vunit/vunit_sample_tbc.vhd](00_test_vunit/vunit_sample_tbc.vhd).
