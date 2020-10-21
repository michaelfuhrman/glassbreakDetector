# Release of bitstreams to Ring
Have shipped 4 trimmed parts: 
* ramp64
* ramp66
* ramp67
* ramp68
Nicolas has pulled the firmware release together. The ultimate bitstream release will have a centered bitstream and part-specific offsets.
But to get Ring started and buy us some time to get comfortable with the trim process, will first release a bitstream to setup the mic 
interface.

Checked that the 4 netlists have the same structure.

Need to figure out how we handle different sign bits.

## [Mic Interface](v00_mic-interface)

Pinout:
| Pin | Function                                                           |
|-----|--------------------------------------------------------------------|
| A0  | Non-inverting mic input, ~2MOhm impedance, use 1uF ac-coupling cap |
| A1  | Program verification readout: should get 1.6-2Vdc                  |
| A2  | Inverting mic input, ~2MOhm impedance, use 1uF ac-coupling cap     |
| A3  | Mic difference amp output, ~1Vdc                                   |
| D0  | Digital output - 0                                                 |
| D1  | Digital output - 0                                                 |
| D2  | Digital output - 0                                                 |
| D3  | Digital output - 0                                                 |

Regarding A1: With an EM1 going through the normal process, I saw ~1.65V. With the H7 setup
and no MCU I saw ~1.92V. Should have the same register settings. Not the same parts though.
Need to look deeper into the FG values and ensure we are getting matching results.

Here's the bytestream
```
511, 64625, 16672, 21554,
22400, 269, 47296, 1083,
26240, 15, 36864, 19582,
8267, 4105, 34818, 44033,
43520, 1279, 65418, 42104,
8473, 23288, 59228, 60317,
471, 53250, 4501, 44942,
30158, 47568, 7676, 49199,
36085, 55040, 14347, 58172,
60317, 29600, 14848, 61,
63424, 2051, 57352, 1940,
144, 4236, 44412, 29614,
30158, 32996, 56, 4337,
8, 31828, 16946, 46577,
52921, 55098, 43026, 31727,
33827, 11103, 7403, 40307,
41016, 32775, 1920, 3600,
1420, 14466, 7680, 9719,
56840, 18006, 48697, 55098,
59200, 28736, 23387, 25648,
59264, 3588, 897, 52992,
4859, 61188, 9003, 24348,
60317, 29600, 14344, 1596,
45519, 28, 526, 30899,
7416, 8, 7936, 2078,
12, 760, 53056, 3586,
63695, 14964, 1024, 33893,
27619, 31983, 48772, 25963,
58238, 64446, 63497, 31752,
18005, 46577, 48759, 51270,
21941, 61887, 15328, 7680,
0
```

Here's the MCU register settings (**Nicolas see the coarse slope/offset and reference trim are different from what was in ramp lib**).
| Register                  | MSP430 Address |  Value | Notes                               |
|---------------------------|----------------|--------|-------------------------------------|
| `ldo_trim`                |         0x19FC | 0x1249 |                                     |
| `reference_trim`          |         0x19FE |      8 | `ramp_get_reference_trim`           |
| `temperature_trim` slope  |         0x19EE |  0x400 | "1"                                 |
| `temperature_trim` offset |         0x19EC |      0 | "0"                                 |
| `vdd_trim` slope          |         0x19FA |  0x400 | "1"                                 |
| `vdd_trim` offset         |         0x19F8 |      0 | "0"                                 |
| `config`'                 |         0x19EA |      1 | "Use external Vdd"                  |
| `dac_fine_trim` slope     |         0x19F6 |      0 | "0"                                 |
| `dac_fine_trim` offset    |         0x19F4 | 0x8640 | "-100"                              |
| `dac_coarse_trim` slope   |         0x19F2 | 0x14A0 | "330" `ramp_get_dac_coarse_slope`   |
| `dac_coarse_trim` offset  |         0x19F0 | 0x8C80 | "-200" `ramp_get_dac_coarse_offset` |
|                           |                |        |                                     |

## To do
* Deeper verification of FG programmed values comparing MSP430 and no MSP430
* Verification of full glass break programmed via ST and not using trim offset capability
* Verification of full glass break programmed via ST and using trim offset capability
* Finalize trim offsets to use in shipped bitstream
