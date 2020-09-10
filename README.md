# c:/Users/Brandon/Aspinity Dropbox glassbreak-sim-ring-v0.0
The first glassbreak detection model bundled for Ring in July 2020. 

## To use
Run build_rampsim.m to generate a bundled rampsim binary. Then run test_rampsim.m to verify it's operation on two audio files.

## Notes
* Had to make changes to the following ramp operators
  * ramp_model_lr.m - to accommodate changes to the neural net code
  * ramp_prerollrecongb.m - to accommodate differences between Matlab and Octave
* Auto-build from Octave didn't work (think this has only been tested in Matlab)
  * Looks like a path issue caused by Octave looking in it's own path for the build tools.
```
c:/octave/octave~2.0/mingw64/bin/../lib/gcc/x86_64-w64-mingw32/7.4.0/../../../../x86_64-w64-mingw32/bin/ld.exe: cannot find -lpthread
collect2.exe: error: ld returned 1 exit status
make: *** [Makefile:20: bin/rampSim.exe] Error 1
```

# Updates

v1/ contains a signal chain complete signal chain that generates a bundled windows rampsim binary. See compileIn.h for 
the sim netlist.

Changes were made in Drobox to make this work
- changes in RAMP_OPERATOR to remove duplicate lines from netlists
- created ramp.learn.ideal (it's in the nn_ideal directory, need to fix how that parses so that it doesn't drop the nn_).
  This replaces the normal neural net and doesn't try to do any hardware specific scaling. This is temporary and needs
  a finetooth review.
- added a LPF to the sim netlist of ramp.ops.zcr in order to match the matlab better. This is a temp fix.
