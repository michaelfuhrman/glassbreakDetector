# Test bundle for RAMP Detector+Preroll --> IAS Simulator

This bundle enables testing of the RAMP+IAS glass break chain. This is meant to be used for setting up the test harness
to run many files. These are rough versions of RAMPsim and IAS simulator and the results are not meant to be indicative
of final results.

## Contact
Bundle put together by Brandon Rumberg (brandon@aspinity.com).

## Directories

* bin/      -- Contains binaries for the IAS simulator and for RAMPsim.
* data/     -- Contains a set of clean glassbreak sounds and a set of glassbreak sounds mixed with background noise.
* settings/ -- Settings for running the tests. Includes lists of files.

## Requirements

These scripts have been tested on WSL on Windows 10. The rampSim is a Windows binary. 

Requires the `sox` tool for audio format conversion. Install with `sudo apt install sox`.

Requires libsndfile on Windows for reading/writing wav files. We have included the `libsndfile-1.dll` in the bin/RAMPsim directory, 
so you should not need to do anything extra. For reference, it can be installed for Windows from the Download
section of http://www.mega-nerd.com/libsndfile/

## Scripts and Usage

The top-level scripts are:
* test\_short.sh -- Run a quick test with just 10 files of each type. Used to verify the setup.
* test\_full.sh  -- Run all of the data files to get detailed results.

The heavy-lifting scripts are:

* rampsim\_ias\_loop.sh -- Loops over a set of files to get results. For example, you can run a loop like this 
  `./rampsim_ias_loop.sh settings/short_gb_files_clean.csv FULL`
  Please see the file for a description of the options.

* rampsim\_ias\_core.sh -- Runs a single file through the pipeline. Has an argument to either run the FULL chain with both RAMP and IAS or 
  just IAS. You can run it like this
  `./rampsim_ias_core.sh data/events/Room1_window_hit_3_W3_window_hit_\(crash\)_event_1_000_000.wav FULL`
  Please see the file for a description of the options.

## Results
When rampsim\_ias\_loop.sh is run, results are printed to std out. The format is shown below. For each file, the rise and fall time (in seconds)
of each RAMP trigger are shown and the notification time of each IAS trigger (in seconds) is shown.
```
RAMP [rise, fall], IAS [time]
[1.002187s, 2.215188s;], [1.18s;]
[1.006062s, 2.105875s;2.123000s, 2.816875s;], [1.18s;]
[1.004500s, 2.228688s;], [1.18s;]
[1.002812s, 1.748625s;], [1.18s;]
[1.003750s, 2.699125s;], [1.18s;]
[1.007125s, 2.461687s;], [1.18s;]
[1.004562s, 2.609750s;], [1.18s;]
[0.729937s, 1.876688s;2.060875s, 3.586500s;], [0.42s;2.21s;]
[0.778562s, 2.165563s;], [0.67s;]
[1.005812s, 1.752563s;1.770375s, 2.508812s;], [0.93s;]
```
