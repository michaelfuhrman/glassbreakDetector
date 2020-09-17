#define COMPILE_IN 1
vector<string> netlistStrings = {
    "",
    "% Amp",
    "% BPF",
    "% DFF",
    "% Design: rampdev net",
    "% Diff Comp",
    "% Log",
    "% Logic",
    "% Minus",
    "% Neural Network",
    "% Overhang",
    "% Pass",
    "% Peak",
    "% Preroll",
    "% Pulse",
    "%% I/O",
    "Add2 In1=log_10_Log In2=log_10_OutOff Out=log_10 Av=1",
    "Add2 In1=log_4_Log In2=log_4_OutOff Out=log_4 Av=1",
    "Add2 In1=peak_3 In2=log_4_InOff Out=log_4_InShift Av=1",
    "Add2 In1=peak_9 In2=log_10_InOff Out=log_10_InShift Av=1",
    "Add2 In1=vos_CmpBot In2=pass_43_pkbot Out=pass_43_vos_CmpBot Av=1",
    "Add2 In1=vos_CmpTop In2=pass_43_pktop Out=pass_43_pktop_vos_CmpTop Av=1",
    "Add2 In1=vos_cmp_20 In2=mid Out=mid_vos_cmp_20 Av=1",
    "Add2 In1=vos_cmp_21 In2=mid Out=mid_vos_cmp_21 Av=1",
    "Add2 In1=vos_cmp_23 In2=mid Out=mid_vos_cmp_23 Av=1",
    "Add2 In1=vos_cmp_25 In2=mid Out=mid_vos_cmp_25 Av=1",
    "Add2 In1=vos_cmp_29 In2=mid Out=mid_vos_cmp_29 Av=1",
    "Add2 In1=vos_cmp_34 In2=mid Out=mid_vos_cmp_34 Av=1",
    "Add2 In1=vos_cmp_37 In2=mid Out=mid_vos_cmp_37 Av=1",
    "Add2 In1=vos_cmp_42 In2=mid Out=mid_vos_cmp_42 Av=1",
    "AmpX In=In Out=amp_14 Av=2.000000e-01",
    "AmpX In=In Out=pass_43 Av=1",
    "AmpX In=log_10 Out=pass_11 Av=1",
    "AmpX In=log_4 Out=pass_5 Av=1",
    "AmpX In=zcr_15_inv Out=zcr_15_fb Av=1.000000e-09",
    "AmpX In=zcr_15_inv Out=zcr_15_filt Av=1",
    "AmpX In=zcr_15_puls Out=zcr_15_pulsI Av=1.000000e-12",
    "And0 In1=CmpTop_trig In2=CmpBot_trig Out=preTrig",
    "And0 In1=cmp_29 In2=cmp_21 Out=gate_30",
    "And0 In1=cmp_34 In2=pulse_32 Out=gate_35",
    "And0 In1=cmp_42 In2=cmp_42 Out=stitchTrig",
    "And0 In1=gate_26 In2=cmp_20 Out=gate_27",
    "CBuf In=InDly Clk=preTrig BufferLoc=BufferLoc Capacity=2000",
    "ChPu In=overhang_22_inNot Out=overhang_22_current Up=1000 Down=10",
    "ChPu In=overhang_24_inNot Out=overhang_24_current Up=20 Down=100",
    "ChPu In=overhang_28_inNot Out=overhang_28_current Up=1000 Down=10",
    "ChPu In=overhang_33_inNot Out=overhang_33_current Up=1000 Down=10",
    "ChPu In=overhang_36_inNot Out=overhang_36_current Up=1000 Down=10",
    "ChPu In=overhang_41_inNot Out=overhang_41_current Up=1000 Down=3",
    "CmpS Pos=nn_ideal_18 Neg=mid_vos_cmp_20 Out=cmp_20 SettleTime=0",
    "CmpS Pos=nn_ideal_19 Neg=mid_vos_cmp_21 Out=cmp_21 SettleTime=0",
    "CmpS Pos=overhang_22 Neg=mid_vos_cmp_23 Out=cmp_23 SettleTime=0",
    "CmpS Pos=overhang_24 Neg=mid_vos_cmp_25 Out=cmp_25 SettleTime=0",
    "CmpS Pos=overhang_28 Neg=mid_vos_cmp_29 Out=cmp_29 SettleTime=0",
    "CmpS Pos=overhang_33 Neg=mid_vos_cmp_34 Out=cmp_34 SettleTime=0",
    "CmpS Pos=overhang_36 Neg=mid_vos_cmp_37 Out=cmp_37 SettleTime=0",
    "CmpS Pos=overhang_41 Neg=mid_vos_cmp_42 Out=cmp_42 SettleTime=0",
    "CmpX Pos=amp_14 Neg=mid Out=zcr_15_dig",
    "CmpX Pos=pass_43 Neg=pass_43_pktop_vos_CmpTop Out=CmpTop",
    "CmpX Pos=pass_43_vos_CmpBot Neg=pass_43 Out=CmpBot",
    "DlyI In=pass_43 Out=InDly Delay=5",
    "Filt In=In Ref=Gnd Out=bpf_2 type=2 order=2 fc=4000 Q=1.394450e+00 Av=-2.000000e-01",
    "Filt In=In Ref=Gnd Out=bpf_8 type=2 order=2 fc=400 Q=1.394450e+00 Av=-2.000000e-01",
    "Filt In=zcr_15_filt Ref=mid Out=zcr_15 Av=1 fc=30 type=0 order=1",
    "LInt In=overhang_22_current Out=overhang_22 rateUp=1 rateDown=1 zeroRes=0 IC=0",
    "LInt In=overhang_24_current Out=overhang_24 rateUp=1 rateDown=1 zeroRes=0 IC=0",
    "LInt In=overhang_28_current Out=overhang_28 rateUp=1 rateDown=1 zeroRes=0 IC=0",
    "LInt In=overhang_33_current Out=overhang_33 rateUp=1 rateDown=1 zeroRes=0 IC=0",
    "LInt In=overhang_36_current Out=overhang_36 rateUp=1 rateDown=1 zeroRes=0 IC=0",
    "LInt In=overhang_41_current Out=overhang_41 rateUp=1 rateDown=1 zeroRes=0 IC=0",
    "LInt In=zcr_15_intIn Out=zcr_15_inv rateUp=6.327752e+11 rateDown=6.327752e+11 zeroRes=0",
    "MACn Out=mac_nn_ideal_18 Offset=-1.803241e+00 In0=nn_ideal_18_z20 Av0=5.590230e-01 In1=nn_ideal_18_z21 Av1=1.416610e+00 In2=nn_ideal_18_z22 Av2=-1.913005e+00 In3=nn_ideal_18_z23 Av3=1.260008e+00 In4=nn_ideal_18_z24 Av4=3.470506e-01 In5=nn_ideal_18_z25 Av5=2.358732e+00 In6=nn_ideal_18_z26 Av6=2.704650e+00 In7=nn_ideal_18_z27 Av7=1.283975e+00",
    "MACn Out=mac_nn_ideal_18_z10 Offset=2.718058e+00 In0=zcr_15_mid Av0=-4.716207e+03 In1=minus_16_mid Av1=-9.450040e+01 In2=minus_17_mid Av2=4.574360e+01",
    "MACn Out=mac_nn_ideal_18_z11 Offset=1.282529e+00 In0=zcr_15_mid Av0=-2.341876e+03 In1=minus_16_mid Av1=-3.146735e+01 In2=minus_17_mid Av2=5.382325e+01",
    "MACn Out=mac_nn_ideal_18_z12 Offset=6.161156e-01 In0=zcr_15_mid Av0=-2.635287e+03 In1=minus_16_mid Av1=-4.711356e+01 In2=minus_17_mid Av2=1.156601e+01",
    "MACn Out=mac_nn_ideal_18_z13 Offset=-9.655212e-01 In0=zcr_15_mid Av0=1.648634e+03 In1=minus_16_mid Av1=-1.457793e+02 In2=minus_17_mid Av2=8.123037e+01",
    "MACn Out=mac_nn_ideal_18_z14 Offset=2.959975e+00 In0=zcr_15_mid Av0=-4.704026e+03 In1=minus_16_mid Av1=-4.019029e+01 In2=minus_17_mid Av2=-1.969729e+02",
    "MACn Out=mac_nn_ideal_18_z15 Offset=-3.676599e+00 In0=zcr_15_mid Av0=2.956836e+03 In1=minus_16_mid Av1=-2.092885e+01 In2=minus_17_mid Av2=1.123223e+02",
    "MACn Out=mac_nn_ideal_18_z16 Offset=1.820769e+00 In0=zcr_15_mid Av0=-4.339555e+03 In1=minus_16_mid Av1=1.447586e+01 In2=minus_17_mid Av2=-7.973881e+00",
    "MACn Out=mac_nn_ideal_18_z17 Offset=-7.789771e-01 In0=zcr_15_mid Av0=2.485085e+02 In1=minus_16_mid Av1=1.195420e+02 In2=minus_17_mid Av2=-1.800644e+01",
    "MACn Out=mac_nn_ideal_18_z20 Offset=-1.941392e-01 In0=nn_ideal_18_z10 Av0=7.648911e-01 In1=nn_ideal_18_z11 Av1=1.770261e-01 In2=nn_ideal_18_z12 Av2=-8.586566e-01 In3=nn_ideal_18_z13 Av3=-2.778514e-01 In4=nn_ideal_18_z14 Av4=5.325808e-01 In5=nn_ideal_18_z15 Av5=4.042215e-01 In6=nn_ideal_18_z16 Av6=2.212654e-01 In7=nn_ideal_18_z17 Av7=1.543332e+00",
    "MACn Out=mac_nn_ideal_18_z21 Offset=-2.186376e-01 In0=nn_ideal_18_z10 Av0=1.005280e+00 In1=nn_ideal_18_z11 Av1=1.095564e+00 In2=nn_ideal_18_z12 Av2=-6.901719e-01 In3=nn_ideal_18_z13 Av3=-6.070784e-01 In4=nn_ideal_18_z14 Av4=-3.303479e-01 In5=nn_ideal_18_z15 Av5=-5.057138e-01 In6=nn_ideal_18_z16 Av6=-8.197168e-01 In7=nn_ideal_18_z17 Av7=2.038161e+00",
    "MACn Out=mac_nn_ideal_18_z22 Offset=-2.624777e-01 In0=nn_ideal_18_z10 Av0=1.320188e+00 In1=nn_ideal_18_z11 Av1=-1.312225e+00 In2=nn_ideal_18_z12 Av2=1.913674e-01 In3=nn_ideal_18_z13 Av3=1.142829e-01 In4=nn_ideal_18_z14 Av4=9.821170e-01 In5=nn_ideal_18_z15 Av5=-2.532998e+00 In6=nn_ideal_18_z16 Av6=-1.238845e-01 In7=nn_ideal_18_z17 Av7=-9.749578e-01",
    "MACn Out=mac_nn_ideal_18_z23 Offset=2.934337e-01 In0=nn_ideal_18_z10 Av0=1.198717e+00 In1=nn_ideal_18_z11 Av1=-1.455488e-01 In2=nn_ideal_18_z12 Av2=3.775621e-01 In3=nn_ideal_18_z13 Av3=7.917760e-01 In4=nn_ideal_18_z14 Av4=-5.211190e-01 In5=nn_ideal_18_z15 Av5=8.196489e-01 In6=nn_ideal_18_z16 Av6=2.063641e+00 In7=nn_ideal_18_z17 Av7=-1.022223e+00",
    "MACn Out=mac_nn_ideal_18_z24 Offset=-6.859479e-01 In0=nn_ideal_18_z10 Av0=2.248520e-01 In1=nn_ideal_18_z11 Av1=2.651910e+00 In2=nn_ideal_18_z12 Av2=1.398108e+00 In3=nn_ideal_18_z13 Av3=9.559839e-01 In4=nn_ideal_18_z14 Av4=6.020087e-01 In5=nn_ideal_18_z15 Av5=3.066008e+00 In6=nn_ideal_18_z16 Av6=-1.151008e+00 In7=nn_ideal_18_z17 Av7=6.855483e-01",
    "MACn Out=mac_nn_ideal_18_z25 Offset=3.571135e-01 In0=nn_ideal_18_z10 Av0=-5.375796e-01 In1=nn_ideal_18_z11 Av1=-4.341463e-01 In2=nn_ideal_18_z12 Av2=-1.942938e+00 In3=nn_ideal_18_z13 Av3=1.533432e+00 In4=nn_ideal_18_z14 Av4=1.262419e+00 In5=nn_ideal_18_z15 Av5=-1.418549e-01 In6=nn_ideal_18_z16 Av6=-6.000917e-01 In7=nn_ideal_18_z17 Av7=-5.015294e-01",
    "MACn Out=mac_nn_ideal_18_z26 Offset=-6.053956e-01 In0=nn_ideal_18_z10 Av0=-1.173242e+00 In1=nn_ideal_18_z11 Av1=1.984646e+00 In2=nn_ideal_18_z12 Av2=2.113322e+00 In3=nn_ideal_18_z13 Av3=-7.729875e-01 In4=nn_ideal_18_z14 Av4=9.666993e-01 In5=nn_ideal_18_z15 Av5=-9.775345e-02 In6=nn_ideal_18_z16 Av6=-7.479090e-01 In7=nn_ideal_18_z17 Av7=2.209941e+00",
    "MACn Out=mac_nn_ideal_18_z27 Offset=-2.449768e-01 In0=nn_ideal_18_z10 Av0=-1.279231e-01 In1=nn_ideal_18_z11 Av1=1.202410e+00 In2=nn_ideal_18_z12 Av2=4.896628e-01 In3=nn_ideal_18_z13 Av3=9.693753e-03 In4=nn_ideal_18_z14 Av4=-1.577537e+00 In5=nn_ideal_18_z15 Av5=-9.068318e-01 In6=nn_ideal_18_z16 Av6=-3.790818e-01 In7=nn_ideal_18_z17 Av7=1.441848e+00",
    "MACn Out=mac_nn_ideal_19 Offset=-5.166688e-02 In0=nn_ideal_19_z20 Av0=-1.143197e+00 In1=nn_ideal_19_z21 Av1=1.692415e+00 In2=nn_ideal_19_z22 Av2=-1.736190e+00 In3=nn_ideal_19_z23 Av3=-3.557349e+00 In4=nn_ideal_19_z24 Av4=3.066595e+00 In5=nn_ideal_19_z25 Av5=-1.224350e+00 In6=nn_ideal_19_z26 Av6=2.754769e+00 In7=nn_ideal_19_z27 Av7=-2.298768e+00",
    "MACn Out=mac_nn_ideal_19_z10 Offset=-3.503859e-01 In0=zcr_15_mid Av0=8.064142e+02 In1=minus_16_mid Av1=3.208531e+02 In2=minus_17_mid Av2=-6.132139e+01",
    "MACn Out=mac_nn_ideal_19_z11 Offset=-1.857716e+00 In0=zcr_15_mid Av0=4.931941e+03 In1=minus_16_mid Av1=-2.946926e+01 In2=minus_17_mid Av2=2.174922e+00",
    "MACn Out=mac_nn_ideal_19_z12 Offset=1.012048e+00 In0=zcr_15_mid Av0=-1.429941e+02 In1=minus_16_mid Av1=-3.021985e+02 In2=minus_17_mid Av2=-2.580238e+02",
    "MACn Out=mac_nn_ideal_19_z13 Offset=8.842716e-01 In0=zcr_15_mid Av0=-1.823227e+03 In1=minus_16_mid Av1=-2.285222e+01 In2=minus_17_mid Av2=3.608179e+01",
    "MACn Out=mac_nn_ideal_19_z14 Offset=-3.161468e+00 In0=zcr_15_mid Av0=5.271392e+03 In1=minus_16_mid Av1=3.534984e+02 In2=minus_17_mid Av2=-8.556620e+00",
    "MACn Out=mac_nn_ideal_19_z15 Offset=-4.751125e+00 In0=zcr_15_mid Av0=4.430166e+03 In1=minus_16_mid Av1=-3.305195e+00 In2=minus_17_mid Av2=6.425777e+00",
    "MACn Out=mac_nn_ideal_19_z16 Offset=-4.042528e-01 In0=zcr_15_mid Av0=3.562473e+02 In1=minus_16_mid Av1=-2.292851e+02 In2=minus_17_mid Av2=-9.388370e+00",
    "MACn Out=mac_nn_ideal_19_z17 Offset=3.671144e+00 In0=zcr_15_mid Av0=-4.819053e+03 In1=minus_16_mid Av1=-6.558565e+00 In2=minus_17_mid Av2=-1.124043e+02",
    "MACn Out=mac_nn_ideal_19_z20 Offset=-1.956460e-01 In0=nn_ideal_19_z10 Av0=-1.787054e+00 In1=nn_ideal_19_z11 Av1=-9.265686e-01 In2=nn_ideal_19_z12 Av2=1.318560e-01 In3=nn_ideal_19_z13 Av3=-7.973266e-01 In4=nn_ideal_19_z14 Av4=2.382244e+00 In5=nn_ideal_19_z15 Av5=-1.790251e+00 In6=nn_ideal_19_z16 Av6=8.488805e-01 In7=nn_ideal_19_z17 Av7=4.608975e-01",
    "MACn Out=mac_nn_ideal_19_z21 Offset=2.391485e-01 In0=nn_ideal_19_z10 Av0=-3.807359e-01 In1=nn_ideal_19_z11 Av1=4.708473e-01 In2=nn_ideal_19_z12 Av2=-1.455704e+00 In3=nn_ideal_19_z13 Av3=1.243885e+00 In4=nn_ideal_19_z14 Av4=7.610000e-02 In5=nn_ideal_19_z15 Av5=-5.107233e-01 In6=nn_ideal_19_z16 Av6=1.429013e+00 In7=nn_ideal_19_z17 Av7=-7.723709e-01",
    "MACn Out=mac_nn_ideal_19_z22 Offset=6.650565e-01 In0=nn_ideal_19_z10 Av0=-4.800213e-01 In1=nn_ideal_19_z11 Av1=-1.582956e+00 In2=nn_ideal_19_z12 Av2=-1.381204e-01 In3=nn_ideal_19_z13 Av3=-1.855409e+00 In4=nn_ideal_19_z14 Av4=6.235924e-01 In5=nn_ideal_19_z15 Av5=5.081888e-01 In6=nn_ideal_19_z16 Av6=1.102027e+00 In7=nn_ideal_19_z17 Av7=-1.320169e+00",
    "MACn Out=mac_nn_ideal_19_z23 Offset=-5.772842e-01 In0=nn_ideal_19_z10 Av0=-8.714024e-01 In1=nn_ideal_19_z11 Av1=1.240279e+00 In2=nn_ideal_19_z12 Av2=-1.566689e-01 In3=nn_ideal_19_z13 Av3=1.965516e+00 In4=nn_ideal_19_z14 Av4=-3.291873e-01 In5=nn_ideal_19_z15 Av5=-2.349979e+00 In6=nn_ideal_19_z16 Av6=-9.379547e-01 In7=nn_ideal_19_z17 Av7=-2.627557e+00",
    "MACn Out=mac_nn_ideal_19_z24 Offset=-7.595845e-01 In0=nn_ideal_19_z10 Av0=-2.560339e-01 In1=nn_ideal_19_z11 Av1=6.528255e-01 In2=nn_ideal_19_z12 Av2=5.999676e-01 In3=nn_ideal_19_z13 Av3=1.764087e+00 In4=nn_ideal_19_z14 Av4=-4.701607e-01 In5=nn_ideal_19_z15 Av5=-1.230644e+00 In6=nn_ideal_19_z16 Av6=2.973362e+00 In7=nn_ideal_19_z17 Av7=-1.466370e+00",
    "MACn Out=mac_nn_ideal_19_z25 Offset=-8.423866e-01 In0=nn_ideal_19_z10 Av0=1.479645e+00 In1=nn_ideal_19_z11 Av1=-3.098855e-01 In2=nn_ideal_19_z12 Av2=-2.529794e-01 In3=nn_ideal_19_z13 Av3=-8.854697e-01 In4=nn_ideal_19_z14 Av4=-9.196524e-01 In5=nn_ideal_19_z15 Av5=1.338822e+00 In6=nn_ideal_19_z16 Av6=-3.226920e-02 In7=nn_ideal_19_z17 Av7=3.139048e+00",
    "MACn Out=mac_nn_ideal_19_z26 Offset=7.383644e-02 In0=nn_ideal_19_z10 Av0=1.331386e+00 In1=nn_ideal_19_z11 Av1=-8.841975e-01 In2=nn_ideal_19_z12 Av2=-1.247293e+00 In3=nn_ideal_19_z13 Av3=-6.339978e-01 In4=nn_ideal_19_z14 Av4=7.949498e-01 In5=nn_ideal_19_z15 Av5=1.084104e-01 In6=nn_ideal_19_z16 Av6=-9.550218e-01 In7=nn_ideal_19_z17 Av7=1.101428e+00",
    "MACn Out=mac_nn_ideal_19_z27 Offset=-7.749964e-01 In0=nn_ideal_19_z10 Av0=-5.656921e-01 In1=nn_ideal_19_z11 Av1=-1.437370e+00 In2=nn_ideal_19_z12 Av2=1.180645e-01 In3=nn_ideal_19_z13 Av3=-3.568450e-01 In4=nn_ideal_19_z14 Av4=5.377936e-02 In5=nn_ideal_19_z15 Av5=-2.915178e-01 In6=nn_ideal_19_z16 Av6=-5.374922e-01 In7=nn_ideal_19_z17 Av7=5.759134e-01",
    "Mlt2 In1=InDly In2=stitchTrig Out=gate Av=0.4",
    "NMir In=log_10_InShift Log=log_10_Log MirOut=log_10_mirOut PreLog=3.700000e-02 InLog=1 Ioff=0",
    "NMir In=log_4_InShift Log=log_4_Log MirOut=log_4_mirOut PreLog=3.700000e-02 InLog=1 Ioff=0",
    "Not0 In1=CmpBot Out=CmpBot_trig",
    "Not0 In1=CmpTop Out=CmpTop_trig",
    "Not0 In1=cmp_21 Out=overhang_22_inNot",
    "Not0 In1=cmp_23 Out=overhang_24_inNot",
    "Not0 In1=cmp_25 Out=gate_26",
    "Not0 In1=cmp_37 Out=overhang_41_inNot",
    "Not0 In1=gate_27 Out=overhang_28_inNot",
    "Not0 In1=gate_35 Out=overhang_36_inNot",
    "Not0 In1=pulse_31 Out=overhang_33_inNot",
    "PkDD In=log_10 Out=peak_12 Saturate=1 a=20 d=90 Par=.4",
    "PkDD In=log_4 Out=peak_6 Saturate=1 a=30 d=90 Par=.4",
    "PkDe In=bpf_2 Out=peak_3 Saturate=1 a=813 d=143",
    "PkDe In=bpf_8 Out=peak_9 Saturate=1 a=813 d=54",
    "PkDe In=pass_43 Out=pass_43_pkbot Saturate=1 a=1000 d=15000",
    "PkDe In=pass_43 Out=pass_43_pktop Saturate=1 a=15000 d=1000",
    "Puls In=gate_27 Out=pulse_31 Time=1.000000e-03",
    "Puls In=gate_30 Out=pulse_32 Time=1.000000e-03",
    "Puls In=zcr_15_dig Out=zcr_15_puls Time=1.000000e-04",
    "Reco BufferLoc=BufferLoc ReconTrigger=stitchTrig Out=reconOut",
    "SIGD In=mac_nn_ideal_18 Out=nn_ideal_18 Av=1",
    "SIGD In=mac_nn_ideal_19 Out=nn_ideal_19 Av=1",
    "Stch In1=reconOut In2=gate Out=prerollrecon_44",
    "Stmp Trig=cmp_42",
    "Sub2 Pos=minus_16 Neg=mid Out=minus_16_mid Av=1",
    "Sub2 Pos=minus_17 Neg=mid Out=minus_17_mid Av=1",
    "Sub2 Pos=pass_11 Neg=peak_12 Out=minus_17 Av=1",
    "Sub2 Pos=pass_5 Neg=peak_6 Out=minus_16 Av=1",
    "Sub2 Pos=zcr_15 Neg=mid Out=zcr_15_mid Av=1",
    "Sub2 Pos=zcr_15_pulsI Neg=zcr_15_fb Out=zcr_15_intIn Av=1",
    "TANH In=mac_nn_ideal_18_z10 Out=nn_ideal_18_z10 Av=1",
    "TANH In=mac_nn_ideal_18_z11 Out=nn_ideal_18_z11 Av=1",
    "TANH In=mac_nn_ideal_18_z12 Out=nn_ideal_18_z12 Av=1",
    "TANH In=mac_nn_ideal_18_z13 Out=nn_ideal_18_z13 Av=1",
    "TANH In=mac_nn_ideal_18_z14 Out=nn_ideal_18_z14 Av=1",
    "TANH In=mac_nn_ideal_18_z15 Out=nn_ideal_18_z15 Av=1",
    "TANH In=mac_nn_ideal_18_z16 Out=nn_ideal_18_z16 Av=1",
    "TANH In=mac_nn_ideal_18_z17 Out=nn_ideal_18_z17 Av=1",
    "TANH In=mac_nn_ideal_18_z20 Out=nn_ideal_18_z20 Av=1",
    "TANH In=mac_nn_ideal_18_z21 Out=nn_ideal_18_z21 Av=1",
    "TANH In=mac_nn_ideal_18_z22 Out=nn_ideal_18_z22 Av=1",
    "TANH In=mac_nn_ideal_18_z23 Out=nn_ideal_18_z23 Av=1",
    "TANH In=mac_nn_ideal_18_z24 Out=nn_ideal_18_z24 Av=1",
    "TANH In=mac_nn_ideal_18_z25 Out=nn_ideal_18_z25 Av=1",
    "TANH In=mac_nn_ideal_18_z26 Out=nn_ideal_18_z26 Av=1",
    "TANH In=mac_nn_ideal_18_z27 Out=nn_ideal_18_z27 Av=1",
    "TANH In=mac_nn_ideal_19_z10 Out=nn_ideal_19_z10 Av=1",
    "TANH In=mac_nn_ideal_19_z11 Out=nn_ideal_19_z11 Av=1",
    "TANH In=mac_nn_ideal_19_z12 Out=nn_ideal_19_z12 Av=1",
    "TANH In=mac_nn_ideal_19_z13 Out=nn_ideal_19_z13 Av=1",
    "TANH In=mac_nn_ideal_19_z14 Out=nn_ideal_19_z14 Av=1",
    "TANH In=mac_nn_ideal_19_z15 Out=nn_ideal_19_z15 Av=1",
    "TANH In=mac_nn_ideal_19_z16 Out=nn_ideal_19_z16 Av=1",
    "TANH In=mac_nn_ideal_19_z17 Out=nn_ideal_19_z17 Av=1",
    "TANH In=mac_nn_ideal_19_z20 Out=nn_ideal_19_z20 Av=1",
    "TANH In=mac_nn_ideal_19_z21 Out=nn_ideal_19_z21 Av=1",
    "TANH In=mac_nn_ideal_19_z22 Out=nn_ideal_19_z22 Av=1",
    "TANH In=mac_nn_ideal_19_z23 Out=nn_ideal_19_z23 Av=1",
    "TANH In=mac_nn_ideal_19_z24 Out=nn_ideal_19_z24 Av=1",
    "TANH In=mac_nn_ideal_19_z25 Out=nn_ideal_19_z25 Av=1",
    "TANH In=mac_nn_ideal_19_z26 Out=nn_ideal_19_z26 Av=1",
    "TANH In=mac_nn_ideal_19_z27 Out=nn_ideal_19_z27 Av=1",
    "Vsrc Pos=In Neg=Gnd WavChan=0 Vdc=0",
    "Vsrc Pos=Vdd Neg=Gnd WavChan=-1 Vdc=2.5",
    "Vsrc Pos=Vhalf Neg=Gnd WavChan=-1 Vdc=1.25",
    "Vsrc Pos=log_10_InOff Neg=Gnd WavChan=-1 Vdc=6.000000e-03",
    "Vsrc Pos=log_10_OutOff Neg=Gnd WavChan=-1 Vdc=2.500000e-01",
    "Vsrc Pos=log_4_InOff Neg=Gnd WavChan=-1 Vdc=6.000000e-03",
    "Vsrc Pos=log_4_OutOff Neg=Gnd WavChan=-1 Vdc=2.500000e-01",
    "Vsrc Pos=mid Neg=Gnd WavChan=-1 Vdc=0",
    "Vsrc Pos=vos_CmpBot Neg=Gnd WavChan=-1 Vdc=-1.000000e-05",
    "Vsrc Pos=vos_CmpTop Neg=Gnd WavChan=-1 Vdc=1.000000e-05",
    "Vsrc Pos=vos_cmp_20 Neg=Gnd WavChan=-1 Vdc=2.000000e-01",
    "Vsrc Pos=vos_cmp_21 Neg=Gnd WavChan=-1 Vdc=2.000000e-01",
    "Vsrc Pos=vos_cmp_23 Neg=Gnd WavChan=-1 Vdc=1.250000e+00",
    "Vsrc Pos=vos_cmp_25 Neg=Gnd WavChan=-1 Vdc=1.250000e+00",
    "Vsrc Pos=vos_cmp_29 Neg=Gnd WavChan=-1 Vdc=1.250000e+00",
    "Vsrc Pos=vos_cmp_34 Neg=Gnd WavChan=-1 Vdc=2.000000e-01",
    "Vsrc Pos=vos_cmp_37 Neg=Gnd WavChan=-1 Vdc=2.000000e-01",
    "Vsrc Pos=vos_cmp_42 Neg=Gnd WavChan=-1 Vdc=3.000000e-01",
    "ONod 0=prerollrecon_44 numChanToOutput=1 1=gate 2=reconOut",
};
