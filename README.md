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

#### Reset
Synchronous entities are expected to behave the same when there is no
reset, or when there is an asynchronous reset.

Hardware requiring synchronous reset will use a script for converting asynchronous
reset to synchronous. This script will be written when there is some need for it,
and will do something like:

```diff
--- async.vhd
+++ sync.vhd
@@ -1,8 +1,9 @@
-process(reset, clock)
+process(clock)
 begin
-	if reset = '1' then
-		some_signal <= '0';
-	elsif rising_edge(clock) then
+	if rising_edge(clock) then
 		some_signal <= not some_signal;
+		if reset = '1' then
+			some_signal <= '0';
+		end if;
 	end if;
 end process;
```

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
./ad7476/00_reset                  : success
./ad7476/01_simple                 : success
./fifo/00_reset                    : success
./fifo/01_reset_preread            : success
./fifo/02_flags                    : success
./fifo/03_simple                   : success
./fifo/04_preread                  : success
./ft245_sync_if/00_reset           : success
./ft245_sync_if/01_xfer            : success
./ft245_sync_if/02_pingpong        : success
./ft245_sync_if/03_counter_to_host : success
./packetizer/00_reset              : success
./packetizer/01_simple             : success
./project/adc2ftd_02/00_reset      : success
./project/adc2ftd_02/01_full       : success
./width_changer/00_reset           : success
./width_changer/01_bigger          : success
./width_changer/02_smaller         : success
./width_changer/03_full            : success
```

### Automated testing
All test benches are run on [Travis CI](https://travis-ci.org), at each commit. The status of the latest run is shown after the title of this page.

## Code
* Code for the host side of FTDI FT245 synchronous fifo is available at [ft2tcp](https://github.com/RandomReaper/ft2tcp)

