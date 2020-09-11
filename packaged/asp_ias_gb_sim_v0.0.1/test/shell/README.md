# Shell usage

The top-level scripts are:
* test\_short.sh -- Run a quick test with just 10 files of each type. Used to verify the setup.
* test\_full.sh  -- Run all of the data files to get detailed results.

The heavy-lifting scripts are:

* rampsim\_ias\_core.sh -- Runs a single file through the pipeline. Has an argument to either run the FULL chain with both RAMP and IAS or 
  just IAS. You can run it like this
  `./rampsim_ias_core.sh test.wav FULL`
  Please see the file for a description of the options.

* rampsim\_ias\_loop.sh -- Loops over a set of files to get results. For example, you can run a loop like this 
  `./rampsim_ias_loop.sh settings/short_gb_files_clean.csv FULL`
  Please see the file for a description of the options.

# Results
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
