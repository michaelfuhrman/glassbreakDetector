
function exploreCumsum
close all

dataDir = fullfile(getenv('AspBox'),'\engr\sig_proc\Projects\External\Infineon\IAS_glassbreak\mgf\glassbreakDetectors\dev\dataMatFiles');
%dataFilename='forReviewingDetectionsLogNNsubtractions.mat';
dataFilename = 'forReviewingDetectionsLogWithTimingLogic_GB_TestClip_v1_16000_mixed_included.mat';
%dataFilename = 'forReviewingDetectionsLog_GB_TestClip_v1_16000.mat'
load(fullfile(dataDir,dataFilename), 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency');

%% Starting point
figure;plot(t,declareThud,'b',t,declareShatter,'r',t,l,'k');

cumShatter = cumsum(ynnShatter);


figure;
plot(t,8e5*declareThud,'b',t,8e5*declareShatter,'r',t,8e5*l,'k');hold on
plot(t,cumShatter,'g','linewidth',1.5)
legend('declareThud','declareShatter','labels','cumsum(ynnShatter)')

shatterList = Detection2List(t,declareShatter);

% idx1 = find(declareShatter);
% idx2 = idx1+4000;

% 50 msec after thud
idx1 = find(declareThud)+800;
% The amount of time we want to sample for
fractionOfSecond = .2; %.15;
samples = fractionOfSecond*16000;
% Index at end of sampling
idx2 = idx1+samples;

% Threshold
nnThresh =.35;

figure;
subplot(311)
sumChatter = (cumShatter(idx2)-cumShatter(idx1))/samples;
%plot(t(idx2),(cumShatter(idx2)-cumShatter(idx1))/4000,'.r',t,.1*l,'k');
plot(t(idx2),sumChatter,'.r','markersize',10);hold on;plot(t,l,'k');
title(['Shatter NN Cumulative Sum Between 50msec to 200msec After Thud with Threshold Shown (' num2str(nnThresh) ')']);
v = axis;v(4) = 1.1;axis(v)
ax(1) = gca;
hold on;
yline(nnThresh,'r')
grid on;
grid minor;

subplot(312)
% Threshold
sumChatterDetections = sumChatter>nnThresh;

idx = find((sumChatter>nnThresh));
detectTimes = t(idx);
lp = zeros(size(t));
lp(idx2(idx))=1;

%plot(t(idx2),(cumShatter(idx2)-cumShatter(idx1))/4000,'.r',t,.1*l,'k');
%plot(t(idx2),sumChatterDetections,'.r','markersize',10);hold on;plot(t,l,'k');
plot(t,lp,'r','markersize',10);hold on;plot(t,l,'k');
title('Threshold Applied to Cumulative Sum');
ax(2) = gca;
hold on;
%yline(nnThresh,'r')
grid on;
grid minor;

subplot(313)
plot(t,declareShatter,'r',t,l,'k')
title('Detections from Thud and Shatter Thresholding and Timing Analysis');
grid on;
grid minor;
ax(3) = gca;
linkaxes(ax)

set(gcf,'position',[27         196        1194         420]);
return
