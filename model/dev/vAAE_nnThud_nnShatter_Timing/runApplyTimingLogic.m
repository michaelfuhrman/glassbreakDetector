function runApplyTimingLogic
close all
dataDir = fullfile(getenv('AspBox'),'\engr\sig_proc\Projects\External\Infineon\IAS_glassbreak\mgf\glassbreakDetectors\dev\dataMatFiles');
load(fullfile(dataDir,'forReviewingDetectionsLogNNsubtractions.mat'), 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency');

SUBTRACTNNS = false;
[declareThud,declareShatter] = applyTimingLogic(t,x,l,ynnThud, ynnShatter, declareThud,declareShatter,SUBTRACTNNS);

figure(1000)
subplot(211)
plot(t,declareThud,'b',t,declareShatter,'r',t,l,'k');
ax(1)=gca;


dataDir = fullfile(getenv('AspBox'),'\engr\sig_proc\Projects\External\Infineon\IAS_glassbreak\mgf\glassbreakDetectors\dev\dataMatFiles');
load(fullfile(dataDir,'forReviewingDetectionsLogNNsubtractions.mat'), 't','x','y','l','ynnThud','ynnShatter','declareThud','declareShatter','labels','gap','acceptableLatency');

SUBTRACTNNS=true;
[declareThud,declareShatter] = applyTimingLogic(t,x,l,ynnThud, ynnShatter, declareThud,declareShatter,SUBTRACTNNS);
figure(1000)
subplot(212)
plot(t,declareThud,'b',t,declareShatter,'r',t,l,'k');
ax(2)=gca;
linkaxes(ax);
return