load gb_nn_structure;
[~, feature_list] = netGen_gb(lib,ramp_ic, []);
nn.io.in = feature_list;
[net_default, feature_list] = netGen_gb(lib,ramp_ic,nn);
