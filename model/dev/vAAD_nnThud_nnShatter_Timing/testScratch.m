

function testScratch
if exist('scratchGlassbreakResults.csv','file')
    delete('scratchGlassbreakResults.csv');
end

for k = 1:5
    [declareShatter, mfilename, wavFile,TPs,FPs,meanLatency,duration] = scratchForDetectionPerformance(k);
    sMethod='singleNN';
    mfilename='scratch';
    fileLength=duration;
    sTPR = num2str(TPs);
    sFalseTriggers = num2str(FPs);
    [~,rootFname] = fileparts(wavFile);
    fid = fopen('scratchGlassbreakResults.csv', 'a');
    % m-file, nn chain, wav filename, duration, missed detects / possible detects, false triggers, mean latency
    fprintf(fid,'%s,%s,%s,%s,%s,%s,%s\n',mfilename,sMethod,rootFname,fileLength,sTPR,sFalseTriggers,meanLatency);
    fclose(fid);
end

% Prepend the glassbreak results with a header
command = 'type ResultsHeader.csv  scratchGlassbreakResults.csv > scratchGlassbreakResults_comparison.csv';
status = system(command);
return


