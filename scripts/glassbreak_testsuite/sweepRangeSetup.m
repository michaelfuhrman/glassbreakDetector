function [thresh,overhang]=sweepRangeSetup(sigArrays,numPoints)
	% Setup a range of threshold and overhang rates to use
	% [thresh,overhang]=sweepRangeSetup(sigArrays,numPoints)
	% Inputs
	%   - sigArrays - set of signals to parse
	%   - numPoints - total number of threshold/overhang combinations to evaluate
	% Outputs
	%   - thresh, overhang

	stats=[];
	stats.event=struct('min',NaN, 'max',NaN, 'mean',NaN, 'std',NaN);
	stats.noise=struct('min',NaN, 'max',NaN, 'mean',NaN, 'std',NaN);
	tests=fieldnames(sigArrays);
	for testNum=1:length(tests)
		thisTest=getfield(sigArrays,tests{testNum});

		for s=1:length(thisTest.x)
			xs=thisTest.x{s}; ls=thisTest.l{s};
			for n=1:length(xs)
				x=xs(n); l=ls(n);
				if isnan(stats.event.min)
					stats.event.min=min(x(l==1)); stats.event.max=max(x(l==1));
					stats.event.mean=mean(x(l==1)); stats.event.std=std(x(l==1));

					stats.noise.min=min(x(l==0)); stats.noise.max=max(x(l==0));
					stats.noise.mean=mean(x(l==0)); stats.noise.std=std(x(l==0));
				else
					if sum(l==1)>0
						stats.event.min=min( stats.event.min, min(x(l==1)) ); stats.event.max=max( stats.event.max, max(x(l==1)) );
						stats.event.mean=mean( [stats.event.mean mean(x(l==1))] ); stats.event.std=mean( [stats.event.std std(x(l==1))] );
					end

					stats.noise.min=min( stats.noise.min, min(x(l==0)) ); stats.noise.max=max( stats.noise.max, max(x(l==0)) );
					stats.noise.mean=mean( [stats.noise.mean mean(x(l==0))] ); stats.noise.std=mean( [stats.noise.std std(x(l==0))] );
				end
			end
		end
	end

	% Set threshold range
	threshMin=stats.event.min; threshMax=stats.event.max;
	thresh=rand(numPoints,1)*(threshMax-threshMin)+threshMin;

	% Set overhang range
	riseMin=100; riseMax=10e4;
	rise=rand(numPoints,1)*(log10(riseMax)-log10(riseMin))+log10(riseMin); rise=10.^rise;

	fallMin=10; fallMax=100;
	fall=rand(numPoints,1)*(log10(fallMax)-log10(fallMin))+log10(fallMin); fall=10.^fall;

	overhang=[rise fall];
