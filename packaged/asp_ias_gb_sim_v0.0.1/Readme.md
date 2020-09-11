# Test bundle for RAMP Detector+Preroll --> IAS Simulator

This bundle enables testing of the RAMP+IAS glass break chain. 

**Version 0.0.1**: This is a followup to Version 0.0.0 (which was previously called
aspinity\_infineon\_gb\_bundle\_2020.07.20). The changes include:

  - A Linux binary in addition to a Windows binary. See bin/ramp_sim.
  - An updated RAMP glassbreak model with lower latency and lower false alarm count.
  - Updated test cases and comparison scripts.

## Contact
Bundle put together by Brandon Rumberg (brandon@aspinity.com).

## Directories

* bin/  -- Contains binaries for the IAS simulator and for ramp_sim.
* data/ -- Contains a 4 minute test case with many glass break sounds and noises.
           Also contains a set of clean glassbreak sounds and a set of glassbreak 
           sounds mixed with background noise that were sent in the previous bundle.
* doc/  -- Documentation on the performance of the model.
* test/ -- Test cases (shell and octave) as well as example for usage.

* settings/ -- Settings for running the tests. Includes lists of files.

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

* [Shell](test/shell/gb_sim_v0.0.1.shell.md): 
* [Octave](test/octave/gb_sim_v0.0.1.octave.ipynb): 

