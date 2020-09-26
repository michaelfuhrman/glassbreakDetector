function InspectDataset(dataset)
  [t,x,l]=LoadDataset(dataset);
  cmdResponse='1'; runNum=1; chanNum=1; listen=0;
  fprintf('\n\nDatabase inspection... Enter h for help\n\n');

  helpInfo={ ...
             "h - help", ...
             "q - quit", ...
             "n - next", ...
             "p - previous", ...
             "l - listen", ...
             "j - down to next channel in signal", ...
             "p - up to previous channel in signal", ...
             "[0-9]* - signal number to jump to", ...
           };
  lastRun=0;
  while cmdResponse~='q'
    switch cmdResponse
      case 'h'
        fprintf('  %s\n',helpInfo{:});
      case 'n'
        runNum=runNum+1;
      case 'p'
        runNum=runNum-1;
      case 'l'
        listen=1;
      case 'j'
        if chanNum<size(val,2)
          chanNum=chanNum+1;
          lastRun=0;
        end
      case 'k'
        if chanNum>1
          chanNum=chanNum-1;
          lastRun=0;
        end
      otherwise
        try
          runNum=str2num(cmdResponse);
        catch
          fprintf('Unknown command\n');
        end
    end

    if runNum~=lastRun
      % Load runNum
      Fs=sig(runNum).Files(1).SampleFreq;
      bg=setxor(1:size(x{runNum},2),chanNum);
      subplot(2,1,1);
      if ~isempty(bg)
        plot(t,val(:,bg)); hold on;
      end
      plot(t,label*max(val(:)),'k'); hold on;
      plot(t,val(:,chanNum),'r','LineWidth',1.5); hold off;
      xlim([t(1) t(end)]);
      title(strrep(sig(runNum).Name,'_',' '));
      subplot(2,1,2); [S,f,ts]=specgram(val(:,chanNum),512,Fs);
      imagesc(ts,f,log(abs(S))); title(sprintf('Channel %d of %d',chanNum,size(val,2)));
      set (gca, "ydir", "normal");

      fprintf('Run %d of %d: %s\n',runNum,length(sig),sig(runNum).Name);
      fprintf('File: %s\n',sig(runNum).Files(1).URI);
      fprintf('Fs: %d, ',Fs);
      fprintf('ChanLabel: %s, ',sig(runNum).Channels(chanNum).Name);
      fprintf('Duration: %d\n',sig(runNum).Stop-sig(runNum).Start);
    end
    lastRun=runNum;
    if listen
      soundsc(val,Fs);
      listen=0;
    end

    fprintf('\n');
    cmdResponse=input('sdbInspect> ','s');
  end
end
