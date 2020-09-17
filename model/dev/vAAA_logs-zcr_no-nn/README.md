# Original model

Directory has build cases and test cases. Release `asp_ias_gb_sim_v0.0.0` has the bundle that was actually sent.

## To use
Run `test_prebuild.m` to check operation without building. Run `build_rampsim.m` to generate a bundled rampsim binary. Then run `test_rampsim.m` to verify it's operation on two audio files.

## Notes
* Had to make changes to the following ramp operators
  * `ramp_model_lr.m` - to accommodate changes to the neural net code
  * `ramp_prerollrecongb.m` - to accommodate differences between Matlab and Octave
* Auto-build from Octave didn't work (think this has only been tested in Matlab)
  * Looks like a path issue caused by Octave looking in it's own path for the build tools.
```
c:/octave/octave~2.0/mingw64/bin/../lib/gcc/x86_64-w64-mingw32/7.4.0/../../../../x86_64-w64-mingw32/bin/ld.exe: cannot find -lpthread
collect2.exe: error: ld returned 1 exit status
make: *** [Makefile:20: bin/rampSim.exe] Error 1
```

