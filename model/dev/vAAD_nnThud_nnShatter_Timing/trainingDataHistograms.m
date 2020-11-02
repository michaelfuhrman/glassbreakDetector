function trainingDataHistograms(y,event_index, noise_index)

X=y([event_index noise_index],:);
Y=[ones(size(event_index)) zeros(size(noise_index))]';

%%
figure;
% Rows passed event_index are background
[N1,X1] = hist(X(length(event_index)+1:end,1),100);
[N2,X2] = hist(X(1:length(event_index),1),100);
subplot(511);
plot(X1,N1/sum(N1),X2,N2/sum(N2))
xlabel('ZCR')
ylabel({'Relative', 'Frequency'})
title(['Acceptable Latency: ' num2str(acceptableLatency) ' Seconds']);
legend('Background ZCR','Glass break ZCR')


[N1,X1] = hist(X(length(event_index)+1:end,2),100);
[N2,X2] = hist(X(1:length(event_index),2),100);
subplot(512);
plot(X1,N1/sum(N1),X2,N2/sum(N2))
axis('tight')
xlabel('Envelope Amplitude')
ylabel({'Relative', 'Frequency'})
v = axis;v(1) = 0;v(3) = 0;axis(v);
legend('Background 4kHz','Glass break 4kHz')

[N1,X1] = hist(X(length(event_index)+1:end,2)-X(length(event_index)+1:end,3),100);
[N2,X2] = hist(X(1:length(event_index),2)-X(1:length(event_index),3),100);
subplot(513);
plot(X1,N1/sum(N1),X2,N2/sum(N2))
axis('tight')
xlabel('Envelope Amplitude')
ylabel({'Relative', 'Frequency'})
v = axis;v(1) = 0;v(3) = 0;axis(v);
legend('Background Minus Baseline 4kHz','Glass break Minus Baseline 4kHz')

[N1,X1] = hist(X(length(event_index)+1:end,4),100);
[N2,X2] = hist(X(1:length(event_index),4),100);
subplot(514);
plot(X1,N1/sum(N1),X2,N2/sum(N2))
axis('tight')
xlabel('Envelope Amplitude')
ylabel({'Relative', 'Frequency'})
v = axis;v(1) = 0;v(3) = 0;axis(v);
legend('Background 400Hz','Glass break 400Hz')

[N1,X1] = hist(X(length(event_index)+1:end,4)-X(length(event_index)+1:end,5),100);
[N2,X2] = hist(X(1:length(event_index),4)-X(1:length(event_index),5),100);
subplot(515);
plot(X1,N1/sum(N1),X2,N2/sum(N2))
axis('tight')
v = axis;v(1) = 0;v(3) = 0;axis(v);
xlabel('Envelope Amplitude')
ylabel({'Relative', 'Frequency'})
legend('Background Minus Baseline 400Hz','Glass break Minus Baseline 400Hz')

set(gcf,'position',[257    57   560   573])

S=y([event_index],:);
N=y([noise_index],:);
if 0
    figure;plot3(S(:,1),S(:,2),S(:,4),'.b');hold on;plot3(N(:,1),N(:,2),N(:,4),'.r')
    v = axis;v(1) = 0;v(3)=0;v(5)=0;axis(v)
    xlabel('ZCR')
    ylabel('4kHz')
    zlabel('400Hz')
end

return