# pim-vhdl [![Build Status](https://travis-ci.org/RandomReaper/pim-vhdl.svg?branch=master)](https://travis-ci.org/RandomReaper/pim-vhdl)

## Why
Because VHDL is hard and should be [free](https://fsf.org/).

## Library organization
| Directory  | Description |
| ------------- | ------------- |
| /bin  | scripts  |
| /hdl/rtl  | VHDL synthetizable code |
| /hdl/bhv  | VHDL code for simulation |
| /board  | Board support packages |
| /board/XXX/projects  | Projects for a specific board |
| /bin  | scripts  |

## Testing
### Manual testing
Install [ghdl](https://github.com/tgingold/ghdl).

#### Testing one test bench
Add the scripts to the PATH, go to the test bench directory and run :
```bash
source bin/env.sh
cd tb/ad7476
ghdl-sim.sh
```
Expected result: ```../../hdl/bhv/clock/clock_stop.vhd:52:8:@100875ns:(assertion note): PIM_VHDL_SIMULATION_DONE```

#### Testing all the test benches
Add the scripts to the PATH, go to the test benches and run them all :
```bash
source bin/env.sh
cd tb
ghdl-all.sh
```
Expected result:
```
success : ./fifo/00_simple/
success : ./fifo/01_flags/
success : ./fifo/02_preread/
success : ./width_changer/01_smaller/
success : ./width_changer/00_bigger/
success : ./width_changer/02_full/
success : ./packetizer/
success : ./project/adc2ftd_02/00_full/
success : ./ad7476/
success : ./ft245_sync_if/02_counter_to_host/
success : ./ft245_sync_if/00_xfer/
success : ./ft245_sync_if/01_pingpong/
```

### Automated testing
All test benches are run on [Travis CI](https://travis-ci.org), at each commit. The status of the latest run is shown after the title of this page.

