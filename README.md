# Glass break models for Ring

The first glassbreak detection model bundled for Ring in July 2020. 

# Original model

Directory v0/ has build cases and test cases. Directory aspinity\_infineon\_gb\_bundle\_2020.07.20/ has the bundle that was actually sent.

## To use
Run build\_rampsim.m to generate a bundled rampsim binary. Then run test_rampsim.m to verify it's operation on two audio files.

## Notes
* Had to make changes to the following ramp operators
  * ramp\_model\_lr.m - to accommodate changes to the neural net code
  * ramp_prerollrecongb.m - to accommodate differences between Matlab and Octave
* Auto-build from Octave didn't work (think this has only been tested in Matlab)
  * Looks like a path issue caused by Octave looking in it's own path for the build tools.
```
c:/octave/octave~2.0/mingw64/bin/../lib/gcc/x86_64-w64-mingw32/7.4.0/../../../../x86_64-w64-mingw32/bin/ld.exe: cannot find -lpthread
collect2.exe: error: ld returned 1 exit status
make: *** [Makefile:20: bin/rampSim.exe] Error 1
```

# Updated model for v1 to send

v1/ contains a signal chain complete signal chain that generates a bundled windows rampsim binary. See compileIn.h for 
the sim netlist.

Changes were made in Drobox to make this work
- changes in RAMP_OPERATOR to remove duplicate lines from netlists
- created ramp.learn.ideal (it's in the nn_ideal directory, need to fix how that parses so that it doesn't drop the nn_).
  This replaces the normal neural net and doesn't try to do any hardware specific scaling. This is temporary and needs
  a finetooth review.
- added a LPF to the sim netlist of ramp.ops.zcr in order to match the matlab better. This is a temp fix.

## To send

- Replicate the way we sent it before. 
- Need to compare against the old model. Should show w/ IFX connection as well?
- How to show and document the results?
