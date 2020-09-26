function evalGrid = genEvalGrid(numPoints,dimensions)
    % Randomly fill in a grid for evaluating tradeoffs
    % evalGrid = genEvalGrid(numPoints,dimensions)
    %
    % Inputs
    %   numPoints - Total number of evaluation points
    %   dimensions - Struct array describing the start, stop, and lin or log for each dimension
    % Outputs
    %   evalGrid - Matrix w/ column for each dimension

    evalGrid=[];
    for d=1:length(dimensions)
        points=rand(numPoints,1);
        start=dimensions(d).start;
        stop=dimensions(d).stop;
        switch dimensions(d).spacing
            case 'linear'
                points=points*(stop-start)+start;
            case 'log'
                stop=log10(stop); start=log10(start);
                points=10.^(points*(stop-start)+start);
            otherwise
                error('Unknown spacing %s',dimensions(d).spacing);
        end
        evalGrid=setfield(evalGrid,dimensions(d).name,points);
    end
end

% dim=struct('name','dim1', 'start',1, 'stop',100, 'spacing','linear');
% dim(2)=struct('name','dim2', 'start',1, 'stop',100, 'spacing','log');
% evalGrid = genEvalGrid(5,dim)
