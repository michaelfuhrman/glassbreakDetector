function [status, result]=bashCall(cmd)
% Like "system" except targeting a Bash shell
%   If system is linux, then it simply runs "system"
%   If system is windows, then it passes the call to the Windows Subsystem
%     for Linux.


if ispc
  % Check for bash
  [~,whereBash]=system('where bash');
  if isempty(regexp(whereBash,':\\Windows\\[a-zA-Z0-9]*\\bash.exe'))
    % Not found
    system('start "" "https://docs.microsoft.com/en-us/windows/wsl/install-win10"');
    error('WSL not installed. Follow directions loaded in the browser, and use the "Ubuntu" option.')
  end

  if is_octave
    % Check 32-bit or 64-bit
    [compilation,range]=computer;
    if ~isempty(strfind(compilation,'w64')) %log2(range)>60 % 64-bit
      syscall=['C:\Windows\system32\bash.exe -c "' cmd '"'];
    else
      syscall=['C:\Windows\Sysnative\bash.exe -c "' cmd '"'];
    end
  else
    syscall=['C:\Windows\system32\bash.exe -c "' cmd '"'];
  end

else
  syscall=cmd;
end

[status,result]=system(syscall);
if status==-1
    error('Bash could not run, you may need to disable the "Use legacy console" option from the Windows command prompt');
end
