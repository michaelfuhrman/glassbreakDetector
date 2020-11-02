function avg_peak=loudness_estimation(window_len,subwindow_len,signal,Fs)
cnt=1;
for win=1:floor(Fs*window_len):length(signal)-floor(Fs*window_len)
    count=1;
    for sub_win=win:floor(Fs*subwindow_len):win+floor(Fs*window_len)-floor(Fs*subwindow_len)
        val=signal(sub_win:sub_win+floor(Fs*subwindow_len));
        peak_to_peak(count)=(max(val)-min(val))/2;
        count=count+1;
    end
    avg_peak(cnt)=mean(peak_to_peak);
    cnt=cnt+1;
end
end