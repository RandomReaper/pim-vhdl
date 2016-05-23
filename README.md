# pim-vhdl [![Build Status](https://travis-ci.org/RandomReaper/pim-vhdl.svg?branch=master)](https://travis-ci.org/RandomReaper/pim-vhdl)

## Why
Because VHDL is hard and should be [free](https://fsf.org/).

## Library organization
```
+── hdl                 <- Re-usable and reused vhdl
|   |
|   +── bhv             <- Simulation hdl, like clock, reset, ...
|   \── rtl             <- Synthetizable hdl
|
+── board
|   \── mimas           <- One directory for each board
|       +── ucf         <- Hardwired ucf, like leds, buttons, ...
|       |
|       +── projects
|       \── hello_leds  <- one directory for each project
|           +── ucf     <- part of the ucf that change with project
|           +── hdl     <- code
|           +── tb      <- testbench
|           \── tmp     <- build tool crap
|
+── tb
|   \── fifo <- one directory for each tb, and at least one tb per hdl entity.
|       +── 00_reset    <- tb for the reset(s)
|       |   +── hdl     <- here goest the 'tb' entity
|       |   \── tmp
|       +── 01_simple
|       \── 02_flags
|
\── travis          <- Travis CI scripts
```

## CodingStyle
### Indentation
**tabs** size **4**
### Synchronous entities
All synchronous entities MUST have at least those signals:

* The clock signal is named ```clock```.
* The asynchronous reset signal is named ```reset```.
* The synchronous reset signal is named ```reset_sync```.

#### Reset
Synchronous entities are expected to behave the same when there is no
reset, when there is a synchronous or an asynchronous reset.

## Testing
* *For windows users*: install [cygwin](https://cygwin.com/setup-x86_64.exe) with at least ```git```, ```wget``` and ```unzip```.

* Install [ghdl](https://github.com/tgingold/ghdl) and add it to your PATH or
let the scripts get it for you.

### Manual testing

#### Testing one test bench
```bash
source bin/env.sh
cd tb/ad7476
sim.sh
```
Expected result: ```../../hdl/bhv/clock/clock_stop.vhd:52:8:@100875ns:(assertion note): PIM_VHDL_SIMULATION_DONE```

#### Testing all the test benches
```bash
source bin/env.sh
cd tb
all.sh
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

