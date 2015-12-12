Expected structure
.
├── hdl  <- Re-usable and reused vhdl
│   ├── bhv <- here goes simulation hdl, like clock, reset, ...
│   └── rtl <- here goes synthetizable hdl
├── board <- hardware boards
│   └── mimas <- one directory for each board
│       └── ucf <- hardwired ucf, like leds
│       ├── projects <- one directory for each project
│           └── hello_leds
│               ├── ucf <- part of the ucf that change with project
│               ├── hdl <- code
│               ├── tb  <- testbench
│               └── tmp <- build tool crap
├── readme_structure.txt
└── tb
    └── clock_reset
        ├── hdl
        └── tmp

