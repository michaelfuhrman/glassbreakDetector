%%%%%%%%%%%%%%%%%%%%%%%%%%
% RampHW Netlist
%   Generated: 10/25/2020 17:48:10
%   PWD: C:\Users\Brandon\Desktop\glassbreak\model\dev\vAAD_ring-parts\v1_tie-together
%%%%%%%%%%%%%%%%%%%%%%%%%%


% Setup mid reference
ramp_ic.info.periph.ref.en_volt.val = 0;
ramp_ic.info.periph.ref.ext_volt.val = 1;


nethw = [];
nethw{end+1}=ramp_ic.pin.vcg({ ...
  'net',{'3','vcg'}, ...
});
nethw{end+1}=ramp_ic.pin.Iref({ ...
  'net',{'ref','vcg'}, ...
});
nethw{end+1}=ramp_ic.dev.pmir({ ...
  'loc',[2 0], ...
  'net',{'out','vcg'}, ...
  'bits',{'inSrcSign',1,'outSrcSign',1}, ...
  'nvm',{'outSrc','Vcg',1.7,'vcg3'}, ...
});
nethw{end+1}.nvmRef={3,2,0,'pmir_outSrc',1.7,3.5e-08,};
nethw{end+1}=ramp_ic.dev.reg({ ...
  'net',{'read','vdd'}, ...
  'loc',[9 7], ...
  'bits',{'bit',1}, ...
});
nethw{end+1}=ramp_ic.dev.reg({ ...
  'net',{'read','gnd'}, ...
  'loc',[9 6], ...
  'bits',{'bit',0}, ...
});
nethw{end+1}=ramp_ic.pin.A0({ ...
  'net',{'in','inPos'}, ...
});
nethw{end+1}=ramp_ic.pin.A2({ ...
  'net',{'in','inNeg'}, ...
});
nethw{end+1}=ramp_ic.pin.A1({ ...
  'net',{'out','inPos'}, ...
});
nethw{end+1}=ramp_ic.pin.D0({ ...
  'net',{'out','preroll_trig'}, ...
});
nethw{end+1}=ramp_ic.pin.D1({ ...
  'net',{'out','thud_declare'}, ...
});
nethw{end+1}=ramp_ic.pin.D2({ ...
  'net',{'out','blinky'}, ...
});
nethw{end+1}=ramp_ic.pin.D3({ ...
  'net',{'out','shatter_declare'}, ...
});
nethw{end+1}=ramp_ic.dev.vga({ ...
  'net',{'pos','inPos','neg','mid','ctrl','n/c','out','in_gain'}, ...
  'loc',[0 1], ...
  'nvm',{'num','gm',6.74332e-06,'vcg3','den','gm',0,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.resi({ ...
  'net',{'kilo','mid','tap','n/c','mega','in_gain'}, ...
  'loc',[0 1], ...
});
nethw{end+1}=ramp_ic.dev.filt({ ...
  'net',{'inLPF','mid','inHPF','mid','inBPF','inPos','out2','bpf_4k'}, ...
  'loc',[1 6], ...
  'nvm',{'gm1','fc',4807.42,'vcg3','gm2','fc',4807.42,'vcg3','gm3','fc',2403.71,'vcg3','buff2','Id',5e-08,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.peak({ ...
  'net',{'in','bpf_4k','out','rms_4k'}, ...
  'loc',[1 6 1], ...
  'nvm',{'atk','rate',22132.4,'vcg3','dec','rate',24.7772,'vcg3','buff','Id',5e-08,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.ota({ ...
  'net',{'pos','rms_4k','neg','mid','out','_rms_4k_log_intlogshift'}, ...
  'nvm',{'gm','gm',2.6826e-06,'vcg3','src','Id',1.3758e-08,'vcg3'}, ...
  'bits',{'log',1,'srcSign',1}, ...
  'loc',[2 5], ...
});
nethw{end+1}=ramp_ic.dev.pfet({ ...
  'net',{'source','rms_4k_log','well','rms_4k_log','gate','_rms_4k_log_intlogshift','drain','n/c'}, ...
  'loc',[3 5], ...
  'nvm',{'sourceCur','Id',2e-08,'vcg3','drainCur','Id',2e-07,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.ms({ ...
  'loc',[6 5], ...
  'nvm',{'gm1','gm',2.08406e-11,'vcg3','gm2','gm',5e-08,'vcg3','pullCur','Id',0,'vcg3','pushCur','Id',0,'vcg3'}, ...
  'net',{'out','noise_4k_log','C1in','n/c','clkC1','n/c','clkN','n/c','clkP','n/c','ctrl','n/c','intNode','n/c','pos','rms_4k_log','neg','noise_4k_log','nGate','n/c','pGate','n/c'}, ...
  'bits',{'CTcap2TapSw',1,'CTcap1TapSw',1,'CTcapRatio',1,'CTcap2OutSw',0,'CTcap1InSw',0,'DTcap2TapSw',0,'DTcap1TapSw',0,'DTcapRatio',1,'DTcap2OutSw',0,'DTcap1InSw',0,'ota2follow',1,'ota2vgnd',0,'intNodeSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.filt({ ...
  'net',{'inLPF','mid','inHPF','mid','inBPF','in_gain','out2','bpf_1k'}, ...
  'loc',[1 4], ...
  'nvm',{'gm1','fc',898.587,'vcg3','gm2','fc',898.587,'vcg3','gm3','fc',684.534,'vcg3','buff2','Id',5e-08,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.peak({ ...
  'net',{'in','bpf_1k','out','rms_1k'}, ...
  'loc',[1 4 1], ...
  'nvm',{'atk','rate',7595.01,'vcg3','dec','rate',9.90514,'vcg3','buff','Id',5e-08,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.filt({ ...
  'net',{'inLPF','mid','inHPF','mid','inBPF','in_gain','out2','bpf_400'}, ...
  'loc',[1 3], ...
  'nvm',{'gm1','fc',295.085,'vcg3','gm2','fc',295.085,'vcg3','gm3','fc',358.365,'vcg3','buff2','Id',5e-08,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.peak({ ...
  'net',{'in','bpf_400','out','rms_400'}, ...
  'loc',[1 3 1], ...
  'nvm',{'atk','rate',3767.58,'vcg3','dec','rate',1.66185,'vcg3','buff','Id',5e-08,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.ota({ ...
  'net',{'pos','rms_400','neg','mid','out','_rms_400_log_intlogshift'}, ...
  'nvm',{'gm','gm',3.0305e-06,'vcg3','src','Id',1.2866e-08,'vcg3'}, ...
  'bits',{'log',1,'srcSign',1}, ...
  'loc',[2 2], ...
});
nethw{end+1}=ramp_ic.dev.pfet({ ...
  'net',{'source','rms_400_log','well','rms_400_log','gate','_rms_400_log_intlogshift','drain','n/c'}, ...
  'loc',[3 2], ...
  'nvm',{'sourceCur','Id',2e-08,'vcg3','drainCur','Id',2e-07,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.ms({ ...
  'loc',[6 2], ...
  'nvm',{'gm1','gm',3.07165e-11,'vcg3','gm2','gm',5e-08,'vcg3','pullCur','Id',0,'vcg3','pushCur','Id',0,'vcg3'}, ...
  'net',{'out','noise_400_log','C1in','n/c','clkC1','n/c','clkN','n/c','clkP','n/c','ctrl','n/c','intNode','n/c','pos','rms_400_log','neg','noise_400_log','nGate','n/c','pGate','n/c'}, ...
  'bits',{'CTcap2TapSw',1,'CTcap1TapSw',1,'CTcapRatio',1,'CTcap2OutSw',0,'CTcap1InSw',0,'DTcap2TapSw',0,'DTcap1TapSw',0,'DTcapRatio',1,'DTcap2OutSw',0,'DTcap1InSw',0,'ota2follow',1,'ota2vgnd',0,'intNodeSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.reg({ ...
  'net',{'read','vddLoc'}, ...
  'loc',[8 0], ...
  'bits',{'bit',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','rms_4k','neg','mid','ctrl','n/c'}, ...
  'loc',[3 6], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','rms_4k_log','neg','noise_4k_log','ctrl','n/c'}, ...
  'loc',[3 5], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','rms_1k','neg','mid','ctrl','n/c'}, ...
  'loc',[3 4], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','rms_400','neg','mid','ctrl','n/c'}, ...
  'loc',[3 3], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','rms_400_log','neg','noise_400_log','ctrl','n/c'}, ...
  'loc',[3 2], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 6 0], ...
  'nvm',{'weight','Id',1.461e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 6 1], ...
  'nvm',{'weight','Id',1.37895e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 6 2], ...
  'nvm',{'weight','Id',2.8097e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 6 3], ...
  'nvm',{'weight','Id',2.49785e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 6 4], ...
  'nvm',{'weight','Id',1.723e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 6 5], ...
  'nvm',{'weight','Id',6.9675e-10,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 6 6], ...
  'nvm',{'weight','Id',5.343e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 6 7], ...
  'nvm',{'weight','Id',1.1164e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 5 0], ...
  'nvm',{'weight','Id',1.25055e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 5 1], ...
  'nvm',{'weight','Id',2.1112e-10,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 5 2], ...
  'nvm',{'weight','Id',4.52735e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 5 3], ...
  'nvm',{'weight','Id',4.92515e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 5 4], ...
  'nvm',{'weight','Id',9.102e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 5 5], ...
  'nvm',{'weight','Id',3.7668e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 5 6], ...
  'nvm',{'weight','Id',5.192e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 5 7], ...
  'nvm',{'weight','Id',3.1837e-10,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 4 0], ...
  'nvm',{'weight','Id',2.71255e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 4 1], ...
  'nvm',{'weight','Id',1.65745e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 4 2], ...
  'nvm',{'weight','Id',4.98555e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 4 3], ...
  'nvm',{'weight','Id',2.84e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 4 4], ...
  'nvm',{'weight','Id',3.11215e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 4 5], ...
  'nvm',{'weight','Id',3.5876e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 4 6], ...
  'nvm',{'weight','Id',9.023e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 4 7], ...
  'nvm',{'weight','Id',3.2475e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 3 0], ...
  'nvm',{'weight','Id',2.06335e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 3 1], ...
  'nvm',{'weight','Id',1.20635e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 3 2], ...
  'nvm',{'weight','Id',1.40455e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 3 3], ...
  'nvm',{'weight','Id',1.71655e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 3 4], ...
  'nvm',{'weight','Id',2.4716e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 3 5], ...
  'nvm',{'weight','Id',7.801e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 3 6], ...
  'nvm',{'weight','Id',3.254e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 3 7], ...
  'nvm',{'weight','Id',3.90065e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 2 0], ...
  'nvm',{'weight','Id',2.6141e-10,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 2 1], ...
  'nvm',{'weight','Id',2.0041e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 2 2], ...
  'nvm',{'weight','Id',2.31115e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 2 3], ...
  'nvm',{'weight','Id',1.42785e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 2 4], ...
  'nvm',{'weight','Id',5.7875e-10,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 2 5], ...
  'nvm',{'weight','Id',1.69075e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 2 6], ...
  'nvm',{'weight','Id',5.5705e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[3 2 7], ...
  'nvm',{'weight','Id',2.5162e-10,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_0_0','outI','n/c'}, ...
  'loc',[3 0], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',1.1929e-08,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_0_1','outI','n/c'}, ...
  'loc',[3 1], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',1.181e-08,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_0_2','outI','n/c'}, ...
  'loc',[3 2], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',2.4464e-09,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_0_3','outI','n/c'}, ...
  'loc',[3 3], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',2.2283e-09,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_0_4','outI','n/c'}, ...
  'loc',[3 4], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',1.4124e-08,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_0_5','outI','n/c'}, ...
  'loc',[3 5], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',2.1296e-09,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_0_6','outI','n/c'}, ...
  'loc',[3 6], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',2.0908e-09,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_0_7','outI','n/c'}, ...
  'loc',[3 7], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',1.1834e-08,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_0_0','neg','mid','ctrl','n/c'}, ...
  'loc',[4 0], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_0_1','neg','mid','ctrl','n/c'}, ...
  'loc',[4 1], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_0_2','neg','mid','ctrl','n/c'}, ...
  'loc',[4 2], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_0_3','neg','mid','ctrl','n/c'}, ...
  'loc',[4 3], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_0_4','neg','mid','ctrl','n/c'}, ...
  'loc',[4 4], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_0_5','neg','mid','ctrl','n/c'}, ...
  'loc',[4 5], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_0_6','neg','mid','ctrl','n/c'}, ...
  'loc',[4 6], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_0_7','neg','mid','ctrl','n/c'}, ...
  'loc',[4 7], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 0 4], ...
  'nvm',{'weight','Id',1.7163e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 0 5], ...
  'nvm',{'weight','Id',8.306e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 1 4], ...
  'nvm',{'weight','Id',6.457e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 1 5], ...
  'nvm',{'weight','Id',4.33475e-11,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 2 4], ...
  'nvm',{'weight','Id',3.56755e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 2 5], ...
  'nvm',{'weight','Id',1.6416e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 3 4], ...
  'nvm',{'weight','Id',7.128e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 3 5], ...
  'nvm',{'weight','Id',3.1861e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 4 4], ...
  'nvm',{'weight','Id',4.0934e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 4 5], ...
  'nvm',{'weight','Id',6.381e-10,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 5 4], ...
  'nvm',{'weight','Id',3.01545e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 5 5], ...
  'nvm',{'weight','Id',9.6085e-11,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 6 4], ...
  'nvm',{'weight','Id',3.3073e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 6 5], ...
  'nvm',{'weight','Id',6.5685e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 7 4], ...
  'nvm',{'weight','Id',2.3893e-10,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[4 7 5], ...
  'nvm',{'weight','Id',2.18005e-09,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_1_0','outI','n/c'}, ...
  'loc',[4 4], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',4.6959e-10,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_nn_thud_z_1_1','outI','n/c'}, ...
  'loc',[4 5], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',7.9847e-10,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_1_0','neg','mid','ctrl','n/c'}, ...
  'loc',[5 4], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnIn({ ...
  'net',{'pos','nn_nn_thud_z_1_1','neg','mid','ctrl','n/c'}, ...
  'loc',[5 5], ...
  'nvm',{'gmV2I','gm',1e-07,'vcg3','u','Id',5e-09,'vcg3'}, ...
  'bits',{'IinSw',1,'sigSw',0,'reluSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[5 4 4], ...
  'nvm',{'weight','Id',7.6575e-09,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[5 5 4], ...
  'nvm',{'weight','Id',0,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[5 4 5], ...
  'nvm',{'weight','Id',0,'vcg3'}, ...
  'bits',{'sign',0}, ...
});
nethw{end+1}=ramp_ic.dev.nnW({ ...
  'loc',[5 5 5], ...
  'nvm',{'weight','Id',1e-08,'vcg3'}, ...
  'bits',{'sign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_thud','outI','n/c'}, ...
  'loc',[5 4], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',2.5077e-10,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',1}, ...
});
nethw{end+1}=ramp_ic.dev.nnOut({ ...
  'net',{'outV','nn_shatter','outI','n/c'}, ...
  'loc',[5 5], ...
  'nvm',{'gmI2V','gm',1e-07,'vcg3','bias','Id',1.386e-09,'vcg3','buff','Id',5e-08,'vcg3'}, ...
  'bits',{'IoutSw',0,'biasSign',1}, ...
});
nethw{end+1}=ramp_ic.dev.ms({ ...
  'loc',[7 4], ...
  'nvm',{'gm1','gm',8.66155e-11,'vcg3','gm2','gm',5e-08,'vcg3','pullCur','Id',0,'vcg3','pushCur','Id',0,'vcg3'}, ...
  'net',{'out','thud_filt','C1in','n/c','clkC1','n/c','clkN','n/c','clkP','n/c','ctrl','n/c','intNode','n/c','pos','nn_thud','neg','thud_filt','nGate','n/c','pGate','n/c'}, ...
  'bits',{'CTcap2TapSw',1,'CTcap1TapSw',1,'CTcapRatio',1,'CTcap2OutSw',0,'CTcap1InSw',0,'DTcap2TapSw',0,'DTcap1TapSw',0,'DTcapRatio',1,'DTcap2OutSw',0,'DTcap1InSw',0,'ota2follow',1,'ota2vgnd',0,'intNodeSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.ms({ ...
  'loc',[7 5], ...
  'nvm',{'gm1','gm',5.51913e-11,'vcg3','gm2','gm',5e-08,'vcg3','pullCur','Id',0,'vcg3','pushCur','Id',0,'vcg3'}, ...
  'net',{'out','shatter_filt','C1in','n/c','clkC1','n/c','clkN','n/c','clkP','n/c','ctrl','n/c','intNode','n/c','pos','nn_shatter','neg','shatter_filt','nGate','n/c','pGate','n/c'}, ...
  'bits',{'CTcap2TapSw',1,'CTcap1TapSw',1,'CTcapRatio',1,'CTcap2OutSw',0,'CTcap1InSw',0,'DTcap2TapSw',0,'DTcap1TapSw',0,'DTcapRatio',1,'DTcap2OutSw',0,'DTcap1InSw',0,'ota2follow',1,'ota2vgnd',0,'intNodeSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.fgota({ ...
  'net',{'pos','mid','neg','thud_filt','out','thud_cmp_cmp2int'}, ...
  'nvm',{'gm','gm',3e-06,'vcg3','posCharge','Vcg',1.48214,'vcg3','negCharge','Vcg',1.5,'vcg3'}, ...
  'loc',[4 4], ...
});
nethw{end+1}=ramp_ic.dev.mifg({ ...
  'net',{'source','vddLoc','gate1','thud_cmp_cmp2int','gate2','thud_cmp_cmp2int','drain','thud_cmp'}, ...
  'loc',[5 4], ...
  'nvm',{'sourceCur','Id',0,'vcg3','drainCur','Id',5e-07,'vcg3'}, ...
  'bits',{'pseudo',1}, ...
});
nethw{end+1}=ramp_ic.dev.fgota({ ...
  'net',{'pos','mid','neg','shatter_filt','out','shatter_cmp_cmp2int'}, ...
  'nvm',{'gm','gm',3e-06,'vcg3','posCharge','Vcg',1.4605,'vcg3','negCharge','Vcg',1.5,'vcg3'}, ...
  'loc',[4 5], ...
});
nethw{end+1}=ramp_ic.dev.mifg({ ...
  'net',{'source','vddLoc','gate1','shatter_cmp_cmp2int','gate2','shatter_cmp_cmp2int','drain','shatter_cmp'}, ...
  'loc',[5 5], ...
  'nvm',{'sourceCur','Id',0,'vcg3','drainCur','Id',5e-07,'vcg3'}, ...
  'bits',{'pseudo',1}, ...
});
nethw{end+1}=ramp_ic.dev.ms({ ...
  'loc',[7 7], ...
  'nvm',{'gm1','gm',0,'vcg3','gm2','gm',7e-07,'vcg3','pullCur','Id',2.33707e-09,'vcg3','pushCur','Id',8.26227e-12,'vcg3'}, ...
  'net',{'out','thud_hang','C1in','n/c','clkC1','n/c','clkN','n/c','clkP','n/c','ctrl','n/c','intNode','n/c','pos','n/c','neg','n/c','nGate','thud_cmp','pGate','thud_cmp'}, ...
  'bits',{'CTcap2TapSw',0,'CTcap1TapSw',1,'CTcapRatio',0,'CTcap2OutSw',0,'CTcap1InSw',0,'DTcap2TapSw',0,'DTcap1TapSw',0,'DTcapRatio',1,'DTcap2OutSw',0,'DTcap1InSw',0,'ota2follow',0,'ota2vgnd',1,'intNodeSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.mifg({ ...
  'net',{'source','vddLoc','gate1','thud_hang','gate2','thud_hang','drain','thud_hang_inv'}, ...
  'loc',[5 7], ...
  'nvm',{'sourceCur','Id',0,'vcg3','drainCur','Id',3e-07,'vcg3'}, ...
  'bits',{'pseudo',1}, ...
});
nethw{end+1}=ramp_ic.dev.ms({ ...
  'loc',[7 3], ...
  'nvm',{'gm1','gm',0,'vcg3','gm2','gm',7e-07,'vcg3','pullCur','Id',4.86e-10,'vcg3','pushCur','Id',8.80988e-12,'vcg3'}, ...
  'net',{'out','shatter_hang','C1in','n/c','clkC1','n/c','clkN','n/c','clkP','n/c','ctrl','n/c','intNode','n/c','pos','n/c','neg','n/c','nGate','shatter_cmp','pGate','shatter_cmp'}, ...
  'bits',{'CTcap2TapSw',0,'CTcap1TapSw',1,'CTcapRatio',0,'CTcap2OutSw',0,'CTcap1InSw',0,'DTcap2TapSw',0,'DTcap1TapSw',0,'DTcapRatio',1,'DTcap2OutSw',0,'DTcap1InSw',0,'ota2follow',0,'ota2vgnd',1,'intNodeSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.mifg({ ...
  'net',{'source','vddLoc','gate1','shatter_hang','gate2','shatter_hang','drain','shatter_hang_inv'}, ...
  'loc',[5 3], ...
  'nvm',{'sourceCur','Id',0,'vcg3','drainCur','Id',3e-07,'vcg3'}, ...
  'bits',{'pseudo',1}, ...
});
nethw{end+1}=ramp_ic.dev.clb({ ...
  'net',{'a','thud_cmp','b','shatter_hang_inv','c','n/c','outD','thud_declare','outQ','n/c'}, ...
  'loc',[9 3 0], ...
  'lut',{'lutIn','A & B','lutClk','1','lutRst','1','lutD','Local','lutNeighbor','1'}, ...
});
nethw{end+1}=ramp_ic.dev.clb({ ...
  'net',{'a','shatter_cmp','b','thud_hang_inv','c','shatter_hang_inv','outD','shatter_declare','outQ','n/c'}, ...
  'loc',[9 6 0], ...
  'lut',{'lutIn','A & ~B & C','lutClk','1','lutRst','1','lutD','Local','lutNeighbor','1'}, ...
});
nethw{end+1}=ramp_ic.dev.clb({ ...
  'net',{'a','shatter_declare','b','n/c','c','n/c','outD','blinky','outQ','n/c'}, ...
  'loc',[9 5 0], ...
  'lut',{'lutIn','~A','lutClk','1','lutRst','1','lutD','Local','lutNeighbor','1'}, ...
});
nethw{end+1}=ramp_ic.dev.peak({ ...
  'net',{'in','in_gain','out','in_gain_pktop'}, ...
  'loc',[1 0 2], ...
  'nvm',{'atk','rate',28032.5,'vcg3','dec','rate',196.554,'vcg3','buff','Id',1e-07,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.fgota({ ...
  'net',{'pos','in_gain_pktop','neg','in_gain','out','CmpTop_cmp2int'}, ...
  'nvm',{'gm','gm',3e-06,'vcg3','posCharge','Vcg',1.49261,'vcg3','negCharge','Vcg',1.5,'vcg3'}, ...
  'loc',[4 0], ...
});
nethw{end+1}=ramp_ic.dev.mifg({ ...
  'net',{'source','vddLoc','gate1','CmpTop_cmp2int','gate2','CmpTop_cmp2int','drain','CmpTop'}, ...
  'loc',[5 0], ...
  'nvm',{'sourceCur','Id',0,'vcg3','drainCur','Id',5e-07,'vcg3'}, ...
  'bits',{'pseudo',1}, ...
});
nethw{end+1}=ramp_ic.dev.peak({ ...
  'net',{'in','in_gain','out','in_gain_pkbot'}, ...
  'loc',[1 1 2], ...
  'nvm',{'atk','rate',237.889,'vcg3','dec','rate',20789.8,'vcg3','buff','Id',1e-07,'vcg3'}, ...
});
nethw{end+1}=ramp_ic.dev.fgota({ ...
  'net',{'pos','in_gain','neg','in_gain_pkbot','out','CmpBot_cmp2int'}, ...
  'nvm',{'gm','gm',3e-06,'vcg3','posCharge','Vcg',1.53679,'vcg3','negCharge','Vcg',1.5,'vcg3'}, ...
  'loc',[4 1], ...
});
nethw{end+1}=ramp_ic.dev.mifg({ ...
  'net',{'source','vddLoc','gate1','CmpBot_cmp2int','gate2','CmpBot_cmp2int','drain','CmpBot'}, ...
  'loc',[5 1], ...
  'nvm',{'sourceCur','Id',0,'vcg3','drainCur','Id',5e-07,'vcg3'}, ...
  'bits',{'pseudo',1}, ...
});
nethw{end+1}=ramp_ic.dev.clb({ ...
  'net',{'a','CmpTop','b','n/c','c','CmpTop_rst','outD','n/c','outQ','CmpTop_trig'}, ...
  'loc',[8 0 0], ...
  'lut',{'lutIn','1','lutClk','~A','lutRst','~C','lutD','1','lutNeighbor','1'}, ...
});
nethw{end+1}=ramp_ic.dev.ms({ ...
  'loc',[7 0], ...
  'nvm',{'gm1','gm',0,'vcg3','gm2','gm',1e-06,'vcg3','pullCur','Id',9e-09,'vcg3','pushCur','Id',9e-09,'vcg3'}, ...
  'net',{'out','CmpTop_rst','C1in','n/c','clkC1','n/c','clkN','n/c','clkP','n/c','ctrl','n/c','intNode','n/c','pos','n/c','neg','n/c','nGate','CmpTop_trig','pGate','CmpTop_trig'}, ...
  'bits',{'CTcap2TapSw',0,'CTcap1TapSw',0,'CTcapRatio',0,'CTcap2OutSw',0,'CTcap1InSw',0,'DTcap2TapSw',0,'DTcap1TapSw',0,'DTcapRatio',1,'DTcap2OutSw',0,'DTcap1InSw',0,'ota2follow',0,'ota2vgnd',1,'intNodeSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.clb({ ...
  'net',{'a','CmpBot','b','n/c','c','CmpBot_rst','outD','n/c','outQ','CmpBot_trig'}, ...
  'loc',[8 1 0], ...
  'lut',{'lutIn','1','lutClk','~A','lutRst','~C','lutD','1','lutNeighbor','1'}, ...
});
nethw{end+1}=ramp_ic.dev.ms({ ...
  'loc',[7 1], ...
  'nvm',{'gm1','gm',0,'vcg3','gm2','gm',1e-06,'vcg3','pullCur','Id',9e-09,'vcg3','pushCur','Id',9e-09,'vcg3'}, ...
  'net',{'out','CmpBot_rst','C1in','n/c','clkC1','n/c','clkN','n/c','clkP','n/c','ctrl','n/c','intNode','n/c','pos','n/c','neg','n/c','nGate','CmpBot_trig','pGate','CmpBot_trig'}, ...
  'bits',{'CTcap2TapSw',0,'CTcap1TapSw',0,'CTcapRatio',0,'CTcap2OutSw',0,'CTcap1InSw',0,'DTcap2TapSw',0,'DTcap1TapSw',0,'DTcapRatio',1,'DTcap2OutSw',0,'DTcap1InSw',0,'ota2follow',0,'ota2vgnd',1,'intNodeSw',0}, ...
});
nethw{end+1}=ramp_ic.dev.clb({ ...
  'net',{'a','CmpTop_trig','b','CmpBot_trig','c','n/c','outD','preroll_trig','outQ','n/c'}, ...
  'loc',[8 1 1], ...
  'lut',{'lutIn','A|B','lutClk','1','lutRst','1','lutD','Local','lutNeighbor','1'}, ...
});
nethw{end+1}=ramp_ic.dev.resi({ ...
  'net',{'kilo','inPos','tap','n/c','mega','diff_amp_amp_pos'}, ...
  'loc',[0 3], ...
});
nethw{end+1}=ramp_ic.dev.resi({ ...
  'net',{'kilo','diff_amp_amp_pos','tap','n/c','mega','diff_amp_mid_buff'}, ...
  'loc',[0 4], ...
});
nethw{end+1}=ramp_ic.dev.opamp({ ...
  'net',{'pos','mid','neg','diff_amp_mid_buff','out','diff_amp_mid_buff'}, ...
  'nvm',{'bias','Id',5e-08,'vcg3'}, ...
  'loc',[0 4], ...
});
nethw{end+1}=ramp_ic.dev.resi({ ...
  'net',{'kilo','inNeg','tap','n/c','mega','diff_amp_amp_neg'}, ...
  'loc',[0 6], ...
});
nethw{end+1}=ramp_ic.dev.resi({ ...
  'net',{'kilo','diff_amp_amp_neg','tap','n/c','mega','diff_amp'}, ...
  'loc',[0 7], ...
});
nethw{end+1}=ramp_ic.pin.A3({ ...
  'net',{'out','diff_amp_amp_pos','fb','diff_amp_amp_neg','in','diff_amp'}, ...
});
