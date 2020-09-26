# Exploration of the IAS architecture

[Notebook](ias_ramp_design_tradeoffs.ipynb)

An attempt to understand the tradeoffs between latency, false alarm, and power consumption. 

Outlines many assumption of this project.

## Metrics used in this exploration

Some explanation to the metrics stored:
Columns are the files in the dataset, and rows are for every threshold
- 'det_time' has all the times that the Output does above the threshold
- 'ture_pos_detection' is the number of true positive events detected by the algorithm
- 'total_events' total number of events present (In case more than a single event is present in file)
- 'latency' each cell should have the array of latencies for every file (in our case right now, there's only one event per file). latency value is NAN if not detected
- 'false_pos_event' number of false positive events (after every trigger, it waits for 0.2 seconds and does not consider detections within this time in the count like we discussed)
- 'noise_time' is the total noise time in the files (in seconds); can be used with 'false_pos_event' to calculate the FP events/min or hour.
