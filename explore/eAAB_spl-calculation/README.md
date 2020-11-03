# Understanding SPL calculations
After Ring did their modeling tests, they came back with questions about what the relationship between the
signal level and the true SPL was. The docs they sent at that time are 
[here](../../model/dev/vAAB_nn-mixed-data/ring-test-results/updates_00/). These questions throw their results
into doubt because their loudness calculations are putting the glassbreak sounds at a lower level, while
putting the noise sounds at a higher level, so we are looking worse both on FRR and FAR.

## Files
- `loudness_estimation.m` - Our interpretation of the loudness calculation that Ring described.
- `spl_extraction.m` - Comparison of our SPL estimators w/ Ring's estimator. Done over the Vitron recordings.
- `spl_extraction_speech.m` - Uses the speech sections of the Vitron recordings to get comparison of the "noise".

## Story
- Background on SPL: https://www.analog.com/en/analog-dialogue/articles/understanding-microphone-sensitivity.html
  - Analog voltage is related to SPL based on RMS and sensitivity - but it gets tricky when the input isn't stationary
- Start w/ simple signals
  - Sine wave: show that the calculations are related through scaling
  - White noise: show that their calculation breaks down
- Our argument
  - This method is overestimating the loudness of glassbreak sounds, so once they are rescaled they are too quiet -- hence higher FRR
    - Overestimates by ~6dB + maybe other scale factors: so glass break is at least 6dB too soft
  - This method is overestimating(?) the loudness of more stationary sounds by an even greater amount
    - We don't know for sure that they are measuring the background noise and the interferers in the same way as the glassbreak
    - Overestimates white noise by 9dB, so it would scale that down to be too soft?
- More complex signals
  - Glassbreak
    - Show that their method gives different results depending on when the glassbreak event occurs
    - Show how SPL estimates change with window duration - put a pin in this for later
  - Speech: because we happened to have speech in those recordings
    - Amazon loudness recommendations: Equivalent speech level and rms over background
    - Show how the difference between glassbreak and speech are different between the methods
