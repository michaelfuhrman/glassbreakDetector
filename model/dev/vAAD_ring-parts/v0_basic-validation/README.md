# Framework to verify multiple NN outputs and overall topology

* Keep the feature chains simple
  * No ZCR
  * No log
  * 2 bands
* Include the diffamp and preroll

![](../doc/v0_target_chain.png)

## First trim

* First trim: The NN output looks heavily attenuated
  * The scale\_nn parameter was on and it scaled divided the first layer's weights by ~3 across the board. 
  * After the first pass it went back in and retrimmed parts of the NN. Is this a problem for dependent bias terms?
  * The feature inputs are pretty low, so could be helpful to scale up the test signal
* Rerunning
  * Turn off scale nn
  * Gain up the input by 2x

## Second trim

* Noticed some spiking in the BPF response that looks like escaping the linear range of the terminating transconductor
  * Reduced the Q and started again. Still saw some of this spiking.
  * Am applying 2x gain, need to check on this. 
  * The input signal is very large at times. Perhaps should keep it at 1x and have gain after the filters if needed
* Neural net response
  * The thud NN looks like a much scaled down version of what it should be
  * The shatter NN is fairly close
* Questions
  * Check mic operation with this setup
  * Is the trim_script centering the signal correctly given how large it is?

## Later Thoughts

* Checked the mic operation -- looks okay, but need to provide a different dc bias and need to cut the gain
* Need to check the timing logic by itself
* Need to revisit the test signal level
* Why doesn't the thud respond?
* Setup training set
* Use log?
* Use ZCR
* Need to characterize the parts we are sending

Next steps
* **Done** Check timing logic by itself
* Setup v1 version
* Include the missing pieces above (mic dc bias & gain, other features (log, zcr, ...) so can gather all and do tradeoffs)
* Setup training set: incorporate findings from Ring's tests
* Revisit test signal level and gain distribution
* Get a better answer on the target signal chain
* Trim
* Check preroll
