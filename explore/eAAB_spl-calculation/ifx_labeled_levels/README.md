# IFX-Labeled SPL Levels
As promised, here are some sample sounds of the real glass break from our “house glass break session”.
Have a listen and let me know, if you have any questions. Here is some more background info for you as well.

As previously discussed, our recordings were done with an NTI Audio Analyzer and a 
140dBSPL microphone located in 2.5m distance from the window.

Here are the measured max values in dBSPL (Lzimax):
- GB1: 107
- GB2: 118
- GB3: 115

Pls note that e.g. in Audacity (what we use), the 0dB line corresponds to 140dBSPL. So, if you take the 
GLASSBREAK_3.WAV file (or short GB3) and run it through Audacity, you should see a max level of about -25dB.
Also note that we use the Lzimax mode on our setup to determine the sound level (loudness) of the glass break. 
This an unweighted mode (no A-weighting) and is most suitable to measure audio signals that exhibit “impulse 
behavior” (short and loud). Not all measurement instruments may have this mode.


## Earlier note from IFX to Ring
If you don’t know yet what min/max values you wish to detect, we can share some observations. For 
instance, a very quiet glass break sound would provide an approximate peak value of -25dB in 
Audacity, if recorded with a 130dBSPL microphone from a distance of 2m (-31dB for 4m and -37dB for 
8m). Those levels should line up with IM73A specs. So, if you want to simulate the reception of 
the very quiet glass break @ 8m, you should consider placing your system in front of the speaker 
(e.g. in 1m distance) and adjust the audio level of the speaker in such way, that the microphone 
in the system shows -37dB. 

## Our notes
This is all 0dBfs = 140dBSPL.

| File         |  Peak | IFX Label | RMS Label | RMS 200ms | RMS 35ms |
|--------------|-------|-----------|-----------|-----------|----------|
| glassbreak_1 | -27.5 | 107 (-33) |       -50 |     -45.7 |      -42 |
| glassbreak_2 |   -22 | 118 (-22) |       -43 |       -36 |      -32 |
| glassbreak_3 |   -28 | 115 (-25) |       -45 |       -42 |      -37 |
