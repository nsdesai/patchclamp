function [isVAR,stimulus] = checkworkspaceforvariable(amplitude)

fileNames = evalin('base','whos');

isVAR = false;

for ii = 1:numel(fileNames)
    
    fN = fileNames(ii).name;
    if strcmp(amplitude,fN)
        isVAR = true;
        break
    end
    
end

if isVAR
    stimulus = evalin('base',amplitude);
    stimulus = stimulus(:);
else
    stimulus = [];
end