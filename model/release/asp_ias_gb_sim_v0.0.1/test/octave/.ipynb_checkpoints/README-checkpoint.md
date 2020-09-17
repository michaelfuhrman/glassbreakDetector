# v0.0.1 Octave Tests

See the [notebook](gb_sim_v0.0.1.octave.ipynb).


## Performance over a larger test set

Additionally, we have performed more detailed testing over a larger set of files with more glass break sounds, 
more noise sounds, and more combinations of SPL. The differences between the v0.0.0 model and the v0.0.1 model
are summarized below.

**Detection rate over SPL***
|        | 85dB | 90dB | 95dB | 100dB | 105dB | 110dB |
|--------|------|------|------|-------|-------|-------|
| v0.0.0 |  70% |  92% |  98% |  100% |  100% |  100% |
| v0.0.1 | 100% | 100% | 100% |  100% |  100% |   96% |

**Detection rate over SNR**
|        | -5dB |  0dB |  5dB | 10dB |
|--------|------|------|------|------|
| v0.0.0 | 100% | 100% | 100% | 100% |
| v0.0.1 |  52% |  82% |  98% |  98% |

**Latency**
|        | Max  |
|--------|------|
| v0.0.0 | 50ms |
| v0.0.1 | 21ms |

**False alarms per minute over continuous background noise SPL**
|        | 65dB | 70dB | 75dB | 80dB | 85dB | 90dB | 95dB |
|--------|------|------|------|------|------|------|------|
| v0.0.0 | 0.33 | 0.97 | 2.78 | 5.67 | 10.5 | 20.0 | 36.2 |
| v0.0.1 | 0.44 | 1.20 | 2.32 | 3.19 | 5.37 | 8.13 | 9.27 |
