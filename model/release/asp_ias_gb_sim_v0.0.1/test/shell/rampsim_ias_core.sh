#!/bin/bash
#
# Brandon Rumberg (brandon@aspinity.com)
#
# Runs a single wav file through the pipeline of
#   ramp_sim detection+preroll --> IAS glassbreak simulator
# Alternatively can run the file through just the IAS glassbreak simulator
#
# Arguments:
#   IN_WAV      = 1st argument, the input wav file
#   METHOD      = Current options are "FULL" for running both ramp_sim and IAS simulator
#                                     "IAS" for only running the IAS simulator
#
# Outputs:
#   Outputs to stdout a string telling the times of the RAMPsim detections and the times
#     of the IAS detections
#   Format is:
#     [RAMP rise1, RAMP fall1; RAMP rise2, RAMP fall2; ...], IAS, [IAS time1; IAS time2; ...]
#
# Example usage:
#  ./rampsim_ias_core.sh test.wav FULL
#  Outputs
#     [1.002937s, 2.510437s;], [1.18s;]

# Grab the arguments
IN_WAV=$1
METHOD=$2

## File definitions
# Audio
RAMPSIM_OUT=.ramp_out.wav
IAS_IN=.ias_in.wav

# Binaries
RAMPSIM="../../bin/ramp_sim/ramp_sim_gb_v0.0.1.exe"
IAS="../../bin/ifx_ias_simulator_v0.3.1/ias_simulator_v031_20200716_08756ca"


if [[ $METHOD == "FULL" ]]; then

    # Run through RAMPsim
    printf "["
    "$RAMPSIM" "$IN_WAV" "$RAMPSIM_OUT" | sed -r 's/.*from ([.0-9]*)s to ([.0-9]*)s.*/\1s, \2s/g' | tr '\n' ';'
    printf "], "

    # Convert RAMPsim floating-point output to fixed-point for IAS
    sox "$RAMPSIM_OUT" -b 16 "$IAS_IN" 2> /dev/null

elif [[ $METHOD == "IAS" ]]; then

    IAS_IN=$IN_WAV

else

    echo Unknown METHOD=$3
    exit -1

fi

# Run through IAS
printf "["
"$IAS" "$IAS_IN" | grep "glassbreak\[" | sed -r 's/.*at ([.0-9]*)s.*/\1s/g' | tr '\n' ';'
printf "]\n"
