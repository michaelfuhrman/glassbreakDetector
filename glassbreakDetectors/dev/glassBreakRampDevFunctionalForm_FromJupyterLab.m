function glassBreakRampDevFunctionalForm_FromJupyterLab

%Octave = exist('OCTAVE_VERSION', 'builtin') == 5

% Todo
%  - Verify each component: sw, rampsim, hw;  bpf, peak, log, zcr, lpf, ...
%  - Get a manageable set of features
%  - Fill in hardware and rampsim details
%  - Convert to trim project

close all

NNSUBTRACTIONS=0;

fileNumber = 1;
dataDir = '../data';
fname{1} = 'GB_TestClip_v1_16000.wav';
fname{2} = 'GB_TestClip_v1_16000_mixed_included.wav';

[~,rootFname] = fileparts(fname{fileNumber});
thisFile = fullfile(dataDir,fname{fileNumber});
disp(['Reading ' thisFile])
[x,Fs]=audioread(thisFile);

t=(0:length(x)-1)/Fs;

%soundsc(x,Fs);

disp(['Fs = ' num2str(Fs)])
disp(['Signal length = ' num2str(t(end)) ' seconds'])

clear labels;
labelName{1}='GB_TestClip_v1_label.csv';
labelName{2}='GB_TestClip_v1_label_mixed_included.csv';

labels=csvread(fullfile(dataDir, labelName{fileNumber}));

l=List2Detections(t,labels);
plot_downsample = 1:10:length(t);
figure;
plot(t(plot_downsample), x(plot_downsample), t(plot_downsample), l(plot_downsample));
xlabel('Time (s)'); legend('Input', 'Label');
drawnow
disp(['Number of labeled glass breaks: ' num2str(length(labels))])

%rng('default');
%rand ("seed", "reset")
ramp_operator_setup;

% Testing different chains
caseNumber = 1;
switch caseNumber
    case 1
        Chain = getChainLog;
        disp('Passed getChainLog')
        gain=1;
        % This is the chain being sent to Ring; it does baseline
        % subtraction
        FeatureChain = ConstructFeatureChain(ramp,gain);
        %Chain = FeatureChain;
        sMethod='Log';
    case 2
        Chain = getChainZCREnvelope;
        sMethod='ZCREnv';
    case 3
        % uses ramp.ideal.tanh instead of ramp.ideal.log
        Chain = getChainTanh;
        sMethod='Tanh';
    case 4
        % Still using ramp.ideal.log; Envelope baseline subtraction
        Chain = getChain3BandLog;
        sMethod='3BandLog';
    otherwise
        disp('other value')
end


% The chain was selected above; Log or Tanh is determined by the chain, not
% the training method
disp('Starting y=Chain(t,x)')
y=Chain(t,x);
% Run the "training data" through the chain
%y = modelChain(Chain, t, x);
figure;
plot(t(plot_downsample), y(plot_downsample,:));
xlabel('Time (s)'); ylabel('Features');
drawnow

if 0
    LPF = ramp.ops.lpf('fc',2e3);
    % ZCR = ramp.ops.zcr();
    % figure;subplot(211);plot(t,ZCR(t,x));subplot(212);plot(t,ZCR(t,BPF(t,x)))
    ZCR = LPF > ramp.ops.zcr() > ...
        ramp.ideal.amp('Av',1e3) > ramp.ops.peak('atk',100, 'dec',4) > ...
        ramp.ops.peak('atk',100, 'dec',100) > ...
        [ramp.ideal.pass();ramp.ops.cmp('thresh',.3)] > ...
        ramp.ideal.mult('Av',.3);
    
    runtimeZCR = LPF > ramp.ops.zcr() > ramp.ideal.amp('Av',1e3) > ...
        ramp.ops.peak('atk',100, 'dec',4) > ramp.ops.peak('atk',100, 'dec',100) > ...
        [ramp.ideal.pass();ramp.ops.cmp('thresh',.3)] > ...
        ramp.ideal.mult('Av',.4);
    figure;
    plot(t,ZCR(t,x),t,l)
end

LPF = ramp.ops.lpf('fc',2e3);
ENV = ramp.ops.peak('atk',100, 'dec',4) > ramp.ops.peak('atk',100, 'dec',100);
runtimeZCR = ramp.ops.zcr() > ramp.ideal.amp('Av',1e3) > ...
    ramp.ops.peak('atk',100, 'dec',4) > ramp.ops.peak('atk',100, 'dec',100) > ...
    [ramp.ideal.pass();ramp.ops.cmp('thresh',.1)] > ramp.ideal.mult('Av',.4);

%y(:,1) = runtimeZCR(t,x);
    

% Train the neural network with the five inputs in y and the labels
iterations=5e3;sIter='5000';

% Train from label to acceptable latency; this was Brandon's original NN
% but this NN is not used so it's commented out
% gap = 0;
% acceptableLatency = .2;
% [nn,S,N]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);

disp('Training Neural Networks')
% Listening for the thud, but not beyond the thud
gap=0;sGap='pt0';
acceptableLatency = .1;sLatency='pt05';
% Directory where the neural networks are being saved
matDir = 'nnMatFiles';
% Include the source of the traing data in the filename
nnTHUD_Name = fullfile(matDir,['nnThud_' sMethod '_gap_' sGap '_latency_' sLatency '_' rootFname '.mat']);
if ~exist(nnTHUD_Name,'file')
    [nnThud,event_indexThud, noise_indexThud]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
    save(nnTHUD_Name, 'nnThud','event_indexThud', 'noise_indexThud','gap','acceptableLatency');
else
    load(nnTHUD_Name, 'nnThud','event_indexThud', 'noise_indexThud','gap','acceptableLatency');    
end

% Now listen beyond the thud
% Don't collect training data until 50msec passed label
gap=.1; sGap = 'pt05';
acceptableLatency = .2;sLatency='pt2';
nnZCR_Name = fullfile(matDir,['nnZCR_' sMethod '_gap_' sGap '_latency_' sLatency '_' rootFname '.mat']);
if ~exist(nnZCR_Name,'file')
    [nnZCR,event_indexZCR, noise_indexZCR]=gb_testClip_train(t,y,l,acceptableLatency,gap,iterations);
    save(nnZCR_Name, 'nnZCR','event_indexZCR', 'noise_indexZCR','gap','acceptableLatency');
else
    load(nnZCR_Name, 'nnZCR','event_indexZCR', 'noise_indexZCR','gap','acceptableLatency');    
end

disp('Neural Networks Created')

if 0 % Madhumita' training method
    % Reinitialize random number generator to get same results
    rng('default')
    nnThudChain = ramp.learn.nn('hidden',[8 8], 'rate', .6, 'epochs',iterations);
    nnZCRChain = ramp.learn.nn('hidden',[8 8], 'rate', .6, 'epochs',iterations);
    
    
    tp=t([event_indexThud, noise_indexThud]);
    nnThudChain = learn(nnThudChain,tp,y([event_indexThud, noise_indexThud],:),l([event_indexThud, noise_indexThud]));
    % Close the figure showing the features and the NN output
    % close all
    
    tp=t([event_indexZCR, noise_indexZCR]);
    nnZCRChain = learn(nnZCRChain,tp,y([event_indexZCR, noise_indexZCR],:),l([event_indexZCR, noise_indexZCR]));
    % Close the figure showing the features and the NN output
    % close all
    
    
    % Evaluating the three neural nets; but skipping Brandon's original
    % ynn=ramp_nn_eval(t,y,nn);
    % Make the NN outputs column vectors
    TRANSPOSE = ramp.ideal.handle('func',@(t,x)x');
    ynnThudChain=TRANSPOSE(t,nnThudChain(t,y));
    ynnShatterChain=TRANSPOSE(t,nnZCRChain(t,y));
end

disp('Evaluating NNs')
if 1
    % Are the two methods for generating and evaluating the NN equivalent?
    ynnThud=ramp_nn_eval(t,y,nnThud)';
    ynnShatter=ramp_nn_eval(t,y,nnZCR)';
    if 0
        figure;
        plot(t,ynnThud,'b',t,ynnThudChain,'--r',t,l,'k');title('ynnThud vs ynnThudChain')
        figure;
        plot(t,ynnShatter,'b',t,ynnShatterChain,'--r',t,l,'k');title('ynnShatter vs ynnShatterChain')
    end
end

% Keep the old variable names
if 0
    ynnThud = ynnThudChain;
    ynnShatter = ynnShatterChain;
    if 1
        figure;
        plot(t,ynnThud,'b',t,ynnThudChain,'--r',t,l,'k');title('ynnThud vs ynnThudChain')
        figure;
        plot(t,ynnShatter,'b',t,ynnShatterChain,'--r',t,l,'k');title('ynnShatter vs ynnShatterChain')
    end    
end

% Threshold the Neural Net (thresh=.5), generate pulse on rising edge,
% apply overhang operator, and amplify to bring down to range of 0 --> 1
% Want a pusle to come out of the comparator

% Perhaps pulse isn't needed in main chain
%NNCHAIN = [nnThudChain > TRANSPOSE; nnZCRChain > TRANSPOSE];

disp('Defining Operators')
% Constants
Vdd = 2.5;
Mid = 2.5/2;

PASS=ramp.ideal.pass();

% This operator is used to create a wide pulse
HANG=ramp.ops.overhang('up',1e3, 'down',10);
CMPpt5=ramp.ops.cmp('thresh',.5);
CMPMID=ramp.ops.cmp('thresh',Mid);
AMPpt4=ramp.ideal.amp('Av',.4);
NOT = ramp.logic.gate('type','not');
AND = ramp.logic.gate('type','and');
TIMER =ramp.ops.timer('slope',100);

% For suppress detections when the ZCR is low
RMS = ramp.ops.peak('atk',100, 'dec',4);

% For declaring glass break
PULSE=ramp.ops.pulse('time',1e-3);

HANG_CMPMID = HANG > CMPMID;
VALIDTHUD = [PASS;
    HANG > CMPMID > NOT] > AND;

if 0
    thresholdedThud = CMPpt5(t,ynnThud);
    thresholdedShatter = CMPpt5(t,ynnShatter);

    % This is a pulse intended to begin with the onset of shatter and
    % remain high through a sequence of shatter pulses
    hangShatter = HANG_CMPMID(t,thresholdedShatter);

    % Look at the sequence of thud followed by shatter
    % This suppresses a thud that was preceded by shatter
    thud_shatter = [thresholdedThud hangShatter];
    validThud = VALIDTHUD(t,thud_shatter);
    
    % Need to find shatter that was preceded by a thud
    % Start with a thud that was not preceded by shatter
    hangValidThud = HANG_CMPMID(t,validThud);

    validShatter = AND(t,[hangValidThud thresholdedShatter]);

    declareThud = AMPpt4(t,PULSE(t,validThud));
    declareShatter = AMPpt4(t,PULSE(t,validShatter));
    
    figure;
    plot(t,declareThud,'b',t,declareShatter,'r',t,.9*l,'k');
    legend('declareThud','declareShatter')
    drawnow
    
    figure;
    subplot(311)
    plot(t,.4*hangShatter,'g',t,.4*thresholdedThud,'b',t,.4*thresholdedShatter,'r',t,.9*l,'k');
    ax(1)=gca;
    legend('hangShatter','thresholdedThud','thresholdedShatter')
    subplot(312)
    plot(t,.4*hangShatter,'g',t,.4*thresholdedThud,'b',t,.4*validThud,'r',t,.9*l,'k');
    ax(2)=gca;
    legend('hangShatter','thresholdedThud','validThud')
    subplot(313)
    plot(t,declareThud,'b',t,declareShatter,'r',t,.9*l,'k');
    legend('declareThud','declareShatter')
    ax(3)=gca;
    linkaxes(ax);
    drawnow
else
    % Intermediate steps
    disp('Threshold the neural networks outputs')
    if NNSUBTRACTIONS==1
        thresholdedThud = CMPpt5(t,ynnThud-10*ynnShatter);
    else
        thresholdedThud = CMPpt5(t,ynnThud);
    end
    
    if NNSUBTRACTIONS==1
        thresholdedShatter = CMPpt5(t,ynnShatter-10*ynnThud);
    else
        thresholdedShatter = CMPpt5(t,ynnShatter);
    end
    
    disp('Generate Delayed the Shatter pulse: Not used PROBLEM WITH RAMPSIM?')
    %DELAY=ramp.ops.delay('delay',.05);
    % thresholdedShatterDelayed = DELAY(t,thresholdedShatter);
    % This is a pulse intended to begin with the onset of shatter and
    % remain high through a sequence of shatter pulses
    %hangShatter = HANG_CMPMID(t,thresholdedShatterDelayed);
    disp('HANG_CMPMID Thresholded Shatter')
    hangShatter = HANG_CMPMID(t,thresholdedShatter);

    % Look at the sequence of thud followed by shatter
    % This suppresses a thud that was preceded by shatter
    thud_shatter = [thresholdedThud hangShatter];
    disp('Valid Thud')
    validThud = VALIDTHUD(t,thud_shatter);
    
    
    % Need to find shatter that was preceded by a thud
    % Start with a thud that was not preceded by shatter
    disp('HANG_CMPMID Valid Thud')
    hangValidThud = HANG_CMPMID(t,validThud);

    %thresholdedShatter = thresholdedShatter + thresholdedShatterDelayed;
    disp('MATLAB CODE ISSUE: Thresholding Shatter')
    thresholdedShatter(thresholdedShatter>2.5) = 2.5;
    
    disp('validShatter using AND')
    validShatter = AND(t,[hangValidThud thresholdedShatter]);
    
    disp('Using PULSE and AMPpt4 to generate declareThud and declareShatter')
    %declareThud = AMPpt4(t,PULSE(t,validThud));
    %declareShatter = AMPpt4(t,PULSE(t,validShatter));
    
    disp('Just running PULSE')
    declareThud = .4*PULSE(t,validThud);
    declareShatter = .4*PULSE(t,validShatter);    
    
    figure
    plot(t(plot_downsample),1.1*declareThud(plot_downsample),'b','linewidth',1);
    hold on;
    plot(t(plot_downsample),1.1*declareShatter(plot_downsample),'r','linewidth',.5);
    plot(t(plot_downsample),l(plot_downsample),'k');
    drawnow
    
    if NNSUBTRACTIONS==1
        title('Thud and Shatter Declarations Before Timing Rules with NNsubtractions');
        %saveas(gcf,fullfile('../doc/FigFiles', ['DeclarationsBeforeTimingWithNNsubtractions_' rootFname '.fig']));
    else
        title('Thud and Shatter Declarations Before Timing Rules without NNsubtractions');
        %saveas(gcf,fullfile('../doc/FigFiles',['DeclarationsBeforeTiming_' rootFname '.fig']));
    end
    
    % This is the chain I gave Madhumita
    %declareThud = AMPpt4(t,PULSE(t,VALIDTHUD(t,[HANG_CMPMID(t,CMPpt5(t,ynnShatter)) CMPpt5(t,ynnThud)])));
    %declareShatter = AMPpt4(t,PULSE(t,AND(t,[HANG_CMPMID(t,VALIDTHUD(t,[CMPpt5(t,ynnThud) HANG_CMPMID(t,CMPpt5(t,ynnShatter))])) CMPpt5(t,ynnShatter)])));
    
    %saveStr =  ['t','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency'];
    dataMatDir = './dataMatFiles';
    switch caseNumber
        case 1
            if NNSUBTRACTIONS == 1
                save(fullfile(dataMatDir,['forReviewingDetectionsLogNNsubtractions_' rootFname '.mat']), 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency');
            else
                save(fullfile(dataMatDir,['forReviewingDetectionsLog_' rootFname '.mat']), 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency');
            end
        case 2
            save(fullfile(dataMatDir,'forReviewingDetectionsLpZCREnvelope.mat', 't','x','y','l','ynnThud','ynnShatter', 'declareThud','declareShatter','labels','gap','acceptableLatency'));
        case 3
            save(fullfile(dataMatDir,'forReviewingDetectionsTanh.mat', 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency'));
        case 4
            save(fullfile(dataMatDir,'forReviewingDetections3BandLog.mat', 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency'));
        otherwise
            disp('other value')
    end
end

if 1
    %subplot(211)
    figure
    plot(t(plot_downsample),1.1*declareThud(plot_downsample),'b','linewidth',1);hold on;
    plot(t(plot_downsample),1.1*declareShatter(plot_downsample),'r','linewidth',.5);
    plot(t(plot_downsample),l(plot_downsample),'k');
    title({'Thud without Shatter is OK: Thud Should Trigger Infineon Detector', 'Shatter Occurs only after Thud', 'Shatter before Thud Suppresses Thud','Shatter before Shatter Suppresses Later Shatter'})
    xlabel('Time (seconds)')
    legend('Thud','Shatter','Labels')
    v=axis;v(4)=1.1;axis(v)
    drawnow
    ax(1) = gca;
    
    if 0
    subplot(212)
    IASchain=ramp.dsp.infineondetector('sensitivity','v3_1');
    IASout = IASchain(t,x);
    plot(t,1.1*IASout,'b',t,l,'k')
    title('ramp.dsp.infineondetector')
    axis(v);
    ax(2)=gca;
    linkaxes(ax,'x');
    set(gcf,'position',[14         198        1225         420]);
    end
end

% At this point we can runReviewDetections to review detections
% ourZCR will get downsampled in the plot
ourZCR = 1e6*y(:,1);
figure
plot(t(plot_downsample),.1*l(plot_downsample),'k','linewidth',2);hold on;
plot(t(plot_downsample),.1*declareThud(plot_downsample),'b',t(plot_downsample),.1*declareShatter(plot_downsample),'r');
hold on;
plot(t(plot_downsample),.01*ourZCR(plot_downsample),'g',t(plot_downsample),y((plot_downsample),[2,3,4]));
legend('Label','Thud','Shatter','ZCR','400Hz','4kHz','6kHz')

%set(gcf,'position',[43          91        1186         420])
figTitle = 'Before Applying Timing Logic: Focusing on Thud and Shatter After Thuds';
title(figTitle)
v = axis;
v(3)=-.01; v(4) = .06;axis(v);
drawnow

return

%saveas(gcf,'viewThudEnvelopes_3BandsPlusZCR.fig')
%mkMovie(t,x,declareThud,declareShatter,figTitle);

% The main chain is used to train and evaluate the neural networks.
% The parallel chain uses rules to suppress false positives
% close all
[declareThud,declareShatter] = applyTimingLogic(t,x,l,ynnThud, ynnShatter, declareThud,declareShatter,NNSUBTRACTIONS);

switch caseNumber
    case 1
        if NNSUBTRACTIONS == 1
            save(fullfile(dataMatDir,['forReviewingDetectionsLogNNsubtractionsWithTimingLogic_' rootFname '.mat']), 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency');
        else
            save(fullfile(dataMatDir,['forReviewingDetectionsLogWithTimingLogic_' rootFname '.mat']), 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency');
        end
    case 2
        save(fullfile(dataMatDir,'forReviewingDetectionsLpZCREnvelopeWithTimingLogic.mat', 't','x','y','l','ynnThud','ynnShatter', 'declareThud','declareShatter','labels','gap','acceptableLatency'));
    case 3
        save(fullfile(dataMatDir,'forReviewingDetectionsTanhWithTimingLogic.mat', 't','x','y','ynnThud','l','ynnShatter', 'declareThud','declareShatter','labels','gap','acceptableLatency'));
    case 4
        save(fullfile(dataMatDir,'forReviewingDetections3BandLogWithTimingLogic.mat', 't','x','y','l','ynnThud','ynnShatter', 'declareThud','declareShatter','labels','gap','acceptableLatency'));
    otherwise
        disp('other value')
end
return

function foo
if 1
    figure;
    subplot(211)
    plot(t,1.1*declareThud,'b','linewidth',1);hold on;plot(t,1.1*declareShatter,'r','linewidth',.5);plot(t,l,'k');
    title({'Thud without Shatter is OK: Thud Should Trigger Infineon Detector', 'Shatter Occurs only after Thud', 'Shatter before Thud Suppresses Thud','Shatter before Shatter Suppresses Later Shatter'})
    xlabel('Time (seconds)')
    legend('Thud','Shatter','Labels')
    v=axis;v(4)=1.1;axis(v)
    ax(1) = gca;
    
    subplot(212)
    IASchain=ramp.dsp.infineondetector('sensitivity','v3_1');
    IASout = IASchain(t,x);
    plot(t,1.1*IASout,'b',t,l,'k')
    title('ramp.dsp.infineondetector')
    axis(v);
    ax(2)=gca;
    linkaxes(ax,'x');
    set(gcf,'position',[14         198        1225         420]);
end

if 0
    figure;
    subplot(211)
    plot(t,1.1*declareThud,'b','linewidth',1);hold on;plot(t,1.1*declareShatter,'r');plot(t,l,'k');
    title({'Thud without Shatter is OK: Thud Should Trigger Infineon Detector', 'Shatter Occurs only after Thud', 'Shatter before Thud Suppresses Thud','Shatter before Shatter Suppresses Later Shatter'})
    xlabel('Time (seconds)')
    legend('Thud','Shatter','Labels')
    v=axis;v(4)=1.1;axis(v)
    ax(1) = gca;
    
    subplot(212)
    IASchain=ramp.dsp.infineondetector('sensitivity','v3_1');
    IASout = IASchain(t,x);
    plot(t,1.1*IASout,'b',t,l,'k')
    title('ramp.dsp.infineondetector')
    axis(v);
    ax(2)=gca;
    linkaxes(ax,'x');
    set(gcf,'position',[14         198        1225         420]);
end
% Whew, what does the final chain look like.
% Time to start glassBreakRampDev_v3.m

% Original:
% uiopen('C:\Users\micha\Aspinity Dropbox\engr\sig_proc\Projects\External\Infineon\IAS_glassbreak\mgf\detectors\glassBreakRampDev_v2.fig',1)


%% Review Detections
%reviewDetections(t,x, y,ynnThud,ynnShatter, declareThud,declareShatter,labels)

return


function [declareThud,declareShatter] = applyTimingLogic_v0(t,x,l,Thud,Shatter)
Thud = 2.5*Thud;
Shatter = 2.5*Shatter;
ramp_operator_setup;

% Additions to the original chain
AND = ramp.logic.gate('type','and');

Cmp = ramp.ops.cmp('thresh',0);

% Pulse name defines width in seconds; triggers on falling edge?
PULSE100=ramp.ops.pulse('time',.1);
PULSE50=ramp.ops.pulse('time',.05);
PULSE10=ramp.ops.pulse('time',1e-2);
PULSE1=ramp.ops.pulse('time',1e-3);
NOT = ramp.logic.gate('type','not');

% Delay the onset for declaring shatter
DELAY5=ramp.ops.delay('delay',.005);

% figure;plot(t,Thud,'b',t,Shatter,'r',t,l,'k')
% axis([1.3895    2.5815    0.3560    2.5506])
% title('Thud and Shatter')

% Shatter declaration comes into the subroutine; now we delay it
delayedShatter = PULSE1(t,NOT(t,DELAY5(t,Shatter)));
% figure;plot(t,Thud,'b',t,delayedShatter,'r',t,l,'k');
% axis([1.3895    2.5815    0.3560    2.5506])

NOTShatter = NOT(t,delayedShatter);

% Gather shatter within 50 msec
wideThud = PULSE50(t,NOT(t,Thud));
% figure;plot(t,wideThud,'b',t,delayedShatter,'r',t,l,'k');
% axis([1.3895    2.5815    0.3560    2.5506])

% Suppress thuds in the midst of shatter leaving valid thuds
validThud = AND(t,[wideThud NOTShatter]);
declareThud = PULSE1(t,validThud);

% figure;plot(t,wideThud,'b',t,AND(t,[wideThud delayedShatter]),'r',t,l,'k');
% axis([1.3895    2.5815    0.3560    2.5506])

declareShatter = AND(t,[wideThud delayedShatter]);
figure;plot(t,declareThud,'b',t,declareShatter,'r',t,l,'k');
return


function [declareThud,declareShatter] = applyTimingLogic_v1(t,x,declareThud,declareShatter)
ramp_operator_setup;

% Additions to the original chain
AND = ramp.logic.gate('type','and');
OVERHANG = ramp.ops.overhang('up',1e3, 'down',10) > ramp.ops.cmp('thresh',.2);
OVERHANGandPULSE = ramp.ops.overhang('up',1e3, 'down',10) > ramp.ops.cmp('thresh',.6) > ramp.ops.pulse('time',1e-3);

declareShatter=.4*AND(t,[OVERHANG(t,2.5*declareThud) 2.5*declareShatter]);
declareShatter=(.4*OVERHANG(t,2.5*declareShatter));

declareThud=(.4*OVERHANGandPULSE(t,2.5*declareThud));
return


function Chain = getChainZCREnvelope
ramp_operator_setup;
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);

% Chain generates five outputs
LPF = ramp.ops.lpf('fc',2e3);
trainZCR = LPF > ramp.ops.zcr() > ramp.ideal.amp('Av',1e3) > ramp.ops.peak('atk',100, 'dec',4) > ramp.ops.peak('atk',100, 'dec',100);
envelopeZCR = LPF > ramp.ops.zcr() > ramp.ideal.amp('Av',1e3) > ramp.ops.peak('atk',100, 'dec',4) > ramp.ops.peak('atk',100, 'dec',100) > ...
    [ramp.ideal.pass();ramp.ops.cmp('thresh',.3)] > ramp.ideal.mult('Av',.4);
Chain=voltageScale > [envelopeZCR; ...
    Chain1; ...
    Chain2];

return

function Chain = getChainLog
ramp_operator_setup;
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);

% Chain generates five outputs
Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); ...
    Chain1; ...
    Chain2];

return


function Chain = getChain3BandLog
ramp_operator_setup;
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',10, 'dec',200, 'modelVersion','PDmodelDynamic')] > ramp.ideal.minus();

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',10, 'dec',200, 'modelVersion','PDmodelDynamic')] > ramp.ideal.minus();

% 6kHz BPF > PkDe > Log > {Pass;Baseline]
Chain3=ramp.ops.bpf('fc',6e3, 'Av',gain) > ramp.ops.peak('atk',12.13e3, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.log('in_offset',6e-3) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',10, 'dec',200, 'modelVersion','PDmodelDynamic')] > ramp.ideal.minus();

voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);

% Chain generates five outputs
Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); ...
    Chain2; ...
    Chain1; ...
    Chain3];

return


function Chain = getChainTanh
ramp_operator_setup;
gain=1;

% Chain1 and Chain2 each generate two outputs
% 4kHz BPF > PkDe > Log > {Pass;Baseline]
Chain1=ramp.ops.bpf('fc',4e3, 'Av',gain) > ramp.ops.peak('atk',8.13e3, 'dec',143, 'modelVersion','PDmodelDynamic') > ramp.ideal.tanh('in_gain',20, 'out_min',0,'out_gain',.18) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
Chain2=ramp.ops.bpf('fc',4e2, 'Av',gain) > ramp.ops.peak('atk',8.13e2, 'dec',54, 'modelVersion','PDmodelDynamic') > ramp.ideal.tanh('in_gain',20, 'out_min',0,'out_gain',.18) > ...
    [ramp.ideal.pass(); ...
    ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

voltageScale=ramp.ideal.scale_fs_v('fs_to_v',-8);

% Chain generates five outputs
Chain=voltageScale > [ramp.ops.zcr() > ramp.ideal.amp('Av',.001); ...
    Chain1; ...
    Chain2];

return

function FeatureChain = ConstructFeatureChain(ramp,gain)
	% 4kHz BPF > PkDe > Log > {Pass;Baseline]
	HiFreq = ramp.ops.bpf('fc',4e3, 'Av',gain) ...
					 > ramp.ops.peak('atk',8.13e2, 'dec',143) ... %, 'modelVersion','PDmodelDynamic') ...
					 > ramp.ideal.log('in_offset',6e-3) ...
					 > [ramp.ideal.pass(); ...
							ramp.ops.peak('atk',30, 'dec',90, 'modelVersion','PDmodelDynamic')];

    % 	HiFreq = ramp.ops.hpf('fc',6e3) ...
    % 					 > ramp.ops.peak('atk',8.13e2, 'dec',143) ... %, 'modelVersion','PDmodelDynamic') ...
    % 					 > ramp.ideal.log('in_offset',6e-3) ...
    % 					 > [ramp.ideal.pass(); ...
    % 							ramp.ops.peak('atk',30, 'dec',90, 'modelVersion','PDmodelDynamic')];

	% 400 Hz BPF > PkDe > Log > {Pass;Baseline]
	LoFreq = ramp.ops.bpf('fc',4e2, 'Av',gain) ...
					 > ramp.ops.peak('atk',8.13e2, 'dec',54) ... %, 'modelVersion','PDmodelDynamic') ...
					 > ramp.ideal.log('in_offset',6e-3) ...
					 > [ramp.ideal.pass(); ...
							ramp.ops.peak('atk',20, 'dec',90, 'modelVersion','PDmodelDynamic')];

	% Chain generates three outputs
	FeatureChain = [ramp.ops.zcr(); ...
									[HiFreq(); HiFreq()] > ramp.ideal.minus(); ...
									[LoFreq(); LoFreq()] > ramp.ideal.minus()];
                                
% 	FeatureChain = [ramp.ops.zcr(); ...
% 									[HiFreq(); HiFreq()]; ...
% 									[LoFreq(); LoFreq()]];                                
return

function mkMovie(t,x,declareThud,declareShatter,figTitle)

title(figTitle)
xlabel('Time (Seconds)');
% First collect the frames
detectionList = Detection2List(t,declareThud);
Fs = 1/(t(2)-t(1));
v = axis;
v(3)=-.01; v(4) = .06;axis(v);
k = 1;
count = 1;
thudAudio = [];
while k < length(detectionList(:,1))
    v(1) = detectionList(k,1)-.1;
    v(2) = detectionList(k,1)+.5;
    title({figTitle,['Detection: ' num2str(k) ' | Frame: ' num2str(count)]})
    axis(v)
    F(count) = getframe(gcf);
    count=count+1;
    thisAudio = x((t>v(1)&(t<v(2))),1);
    soundsc(thisAudio,Fs);
    thudAudio = [thudAudio;thisAudio];
    pause(.61);
    thudIndices = find(detectionList>detectionList(k,1) +.5);
    if ~isempty(thudIndices)
        k = thudIndices(1);
    else
        break;
    end
end

audiowrite('listenThudEnvelopes.wav',thudAudio,Fs);

writerObj = VideoWriter('viewThudEnvelopes.avi');
writerObj.FrameRate = 1;
% set the seconds per image
% open the video writer
open(writerObj);
% write the frames to the video
for i=1:length(F)
    % convert the image to a frame
    frame = F(i) ;
    writeVideo(writerObj, frame);
end
% close the writer object
close(writerObj);
return

