#!/bin/bash
#
# Brandon Rumberg (brandon@aspinity.com)
#
# Loops over a set of files
# Logs the detection results
# Arguments
#   INPUT_FILE_LIST   - 1st arg, csv file containing list of files to run and the event start point of each file
#   METHOD            - 2nd arg, Current options are "FULL" for running the full chain
#                                         "IAS" for only running IAS
#
# Outputs
#   Stdout w/ detection times for RAMP and IAS. For example, running:
#      ./rampsim_ias_loop.sh settings/short_gb_files_mixed.csv FULL
#    Generates this text:
#       RAMP [rise, fall], IAS [time]
#       [1.002187s, 2.215188s;], [1.18s;]
#       [1.006062s, 2.105875s;2.123000s, 2.816875s;], [1.18s;]
#       [1.004500s, 2.228688s;], [1.18s;]
#       [1.002812s, 1.748625s;], [1.18s;]
#       [1.003750s, 2.699125s;], [1.18s;]
#       [1.007125s, 2.461687s;], [1.18s;]
#       [1.004562s, 2.609750s;], [1.18s;]
#       [0.729937s, 1.876688s;2.060875s, 3.586500s;], [0.42s;2.21s;]
#       [0.778562s, 2.165563s;], [0.67s;]
#       [1.005812s, 1.752563s;1.770375s, 2.508812s;], [0.93s;]

# File definitions
INPUT_FILE_LIST=$1
METHOD=$2

printf "\n"
if [[ $METHOD == "FULL" ]]; then
    echo "RAMP [rise, fall], IAS [time]"
else
    echo "IAS [time]"
fi

while read LINE;
do
    # Get file name and true event start time from $INPUT_FILE_LIST
    FILE=$(echo "$LINE" | cut -d "," -f 1)

    # Run the RAMPsim and IAS
    ./rampsim_ias_core.sh $FILE $METHOD
done < $INPUT_FILE_LIST
