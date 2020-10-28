load train_features

thudRange			= [0 .05];
shatterRange	= [0.05 0.2];

%% Extract feature vector
% Non-events are wherever the label is 0
noise_index = find(lab == 0);
noise_index = transpose(noise_index);

% Events are wherever the label is higher for less than the acceptable latency time
labels						= Detection2List(t, lab);

labels_thud	= [labels(:,1)+thudRange(1) ...
							 min(labels(:,2),labels(:,1)+thudRange(2))];
l_thud			= List2Detections(transpose(t), labels_thud);
thud_index	= find(l_thud	== 1);

labels_shatter	= [labels(:,1)+shatterRange(1) ...
									 min(labels(:,2),labels(:,1)+shatterRange(2))];
l_shatter				= List2Detections(transpose(t), labels_shatter);
shatter_index		= find(l_shatter == 1);

noise_index = noise_index(1:10:end);
X = feat([thud_index; shatter_index; noise_index],:);
% X=X(:,1:2:end)-X(:,2:2:end);
Y = [ones(size(thud_index))     zeros(size(thud_index)); ...
		 zeros(size(shatter_index)) ones(size(shatter_index)); ...
		 zeros(size(noise_index))   zeros(size(noise_index))];
plot(1:length(X),X, 1:length(Y), Y);
% X = X(1:50:end,:);
% Y = Y(1:50:end);

rate					= 0.08;
learns				= [.05,			.1,			.3,			.8,			2,		 4,			10,		 20,		40,   100,  200];
learn_thresh	= [0.4e-3,	.3e-3,	.2e-3,	0.1e-3, 75e-6, 50e-6,	40e-6, 30e-6,	20e-6,15e-6,10e-6];

iterations		= 26e3;
hiddenLayers	= [8];


nn		= nn_ramp_nn;
const = nn_get(nn, 'const');

io = struct('in', [], 'stage_in', 3, 'out', []);
io.in = features_list;
io.out{end+1}	= struct('net', 'nn_thud',    'ch',   4);
io.out{end+1}	= struct('net', 'nn_shatter', 'ch',   5);
nn.io = io;

macs= {struct('W',  2*rand(hiddenLayers(1),   length(io.in))-1,   'b',  zeros(hiddenLayers(1),    1)),  ...
       struct('W',  2*rand(length(nn.io.out), hiddenLayers(1))-1, 'b',  zeros(length(nn.io.out),  1))};
act = {struct('type','tanh', 'scale', const.sub_vt_slope), ...
       struct('type','sigd', 'scale', const.sub_vt_slope)};
nn.macs = macs;
nn.act  =  act;
nn.meta.learn = rate;

[yeval, net, nnF] = nn_forward(nn, X, lib);

Y = transpose(Y);
cost = [];
for tr=1:iterations
  % [Out, net, nnF] = nn_forward(nnF, X, lib);
  [Out, net, nnF] = nn_forward_fast(nnF, X, lib);
  [nnF] = nn_backward(nnF, Y);

  OutS = Out * nn.const.sub_vt_slope;
  cost(tr) = -1/length(Y) * sum(sum(( Y.*log(OutS) + (1-Y).*log(1-OutS) )));

	nD_thresh = 1;
	if length(cost)>2
		cost_step = diff(cost(tr-[0:1]));
		nD_thresh = find(cost_step<learn_thresh, 1, 'last');
		nn.meta.learn = learns(nD_thresh);
	end

  if mod(tr,50)==1
    plot(cost); title(sprintf('Training, %d',nD_thresh));
    xlabel('Training iteration'); ylabel('Cost');
    drawnow(); pause(.01);
  end
  if cost(tr)<.05
    break
  end
end


[ynn, net, nnF] = nn_forward(nnF, feat, lib);
nD = 1:10:length(t);
a1 = subplot(2, 1, 1); plot(t(nD), feat(nD, :), t(nD), lab(nD) * max(feat(:)));
a2 = subplot(2, 1, 2); plot(t(nD), ynn(:,nD), t(nD), lab(nD)/const.sub_vt_slope);
