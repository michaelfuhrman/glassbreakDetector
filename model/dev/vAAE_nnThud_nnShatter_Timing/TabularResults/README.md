# Tabular results
Included here are the tabular results for the different processing method. The narrative starts with
generating signal features:
1) high pass filter 
	-> envelope -> log
		-> baseline of log envelope
2) low pass filter
	-> envelope
		-> baseline of log envelope
3) zero crossing rate

In one implementation the envelope baselines are subtracted from the envelopes to leave 3 features.
In a second implementation the envelope and envelope baselines are kept as 5 distinct features.

In another implementation hyperbolic tangents of the envelopes are computed as a surrogate for the logarithms.

In the next step Neural Networks are trained to recognize the sounds of Thud and Shatter.

A glass break event is defined as the sequence of a Thud followed by Shatter. During operation some rules have been implemented to suppress false positives. One rule is the Neural Network output for a Thud should be sampled at a peak in the high frequency channel. Another is that a Thud following Shatter should be suppressed.


