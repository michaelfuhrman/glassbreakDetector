# glassbreak-sim-ring-v0.0
The first glassbreak detection model bundled for Ring in July 2020. 

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
