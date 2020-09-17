# Test bundle for RAMP Detector+Preroll --> IAS Simulator

This bundle enables testing of the RAMP+IAS glass break chain. 

**Version 0.0.1**: This is a followup to Version 0.0.0 (which was previously called
`aspinity_infineon_gb_bundle_2020.07.20`. The changes include:

  - A Linux binary in addition to a Windows binary. See `bin/ramp_sim`.
  - An updated RAMP glassbreak model with lower latency and lower false alarm count.
  - Updated test cases and comparison scripts.

## Contact
Bundle put together by Brandon Rumberg (brandon@aspinity.com).

## Directories

* bin/  -- Contains binaries for the IAS simulator and for ramp_sim.
  * `ramp_sim_gb_v0.0.0.exe` - Previously sent model as Windows binary
  * `ramp_sim_gb_v0.0.1.exe` - New model as Windows binary
  * `ramp_sim_gb_v0.0.1.AppImage` - New model as Linux binary. Can be run as a typical binary. Verified on Ubuntu 18.04. This is Linux only and will not run on WSL1.
* data/ -- Contains a 2-minute test case with many glass break sounds and noises.
           Also contains a set of clean glassbreak sounds.
* doc/  -- Documentation on the performance of the model.
* test/ -- Test cases (shell and octave) as well as example for usage.

## Requirements

These scripts have been tested on WSL on Windows 10 using the ramp\_sim\*.exe
binaries and has been tested on Ubuntu 18.04 LTS using the ramp\_sim*.AppImage 
binaries.

Requires the `sox` tool for audio format conversion. Install with `sudo apt install sox`.

Requires libsndfile on Windows for reading/writing wav files. We have included the 
`libsndfile-1.dll` in the bin/ramp_sim directory, so you should not need to do 
anything extra. For reference, it can be installed for Windows from the Download
section of http://www.mega-nerd.com/libsndfile/

## Test and usage

* [Shell](test/shell/README.md): Instructions for direct use at shell. The same test scripts
  that were provided with v0.0.0.
* [Octave](test/octave/README.md): Examples and results running from Octave.

## Performance over a larger test set

Additionally, we have performed more detailed testing over a larger set of files with more glass break sounds, 
more noise sounds, and more combinations of SPL. The differences between the v0.0.0 model and the v0.0.1 model
are summarized below.

**Detection rate over SPL***
|        | 85dB | 90dB | 95dB | 100dB | 105dB |
|--------|------|------|------|-------|-------|
| v0.0.0 |  70% |  92% |  98% |  100% |  100% |
| v0.0.1 | 100% | 100% | 100% |  100% |  100% |

**Detection rate over SNR**
|        |  5dB | 10dB |
|--------|------|------|
| v0.0.0 | 100% | 100% |
| v0.0.1 |  98% |  98% |

**Latency**
|        | Max  |
|--------|------|
| v0.0.0 | 50ms |
| v0.0.1 | 21ms |

**False alarms per minute over continuous background noise SPL**
|        | 65dB | 70dB | 75dB | 80dB | 85dB | 90dB | 95dB |
|--------|------|------|------|------|------|------|------|
| v0.0.0 | 0.33 | 0.97 | 2.78 | 5.67 | 10.5 | 20.0 | 36.2 |
| v0.0.1 | 0.44 | 1.20 | 2.32 | 3.19 | 5.37 | 8.13 | 9.27 |
