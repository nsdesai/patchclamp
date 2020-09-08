function y = sortmulticlampchannels(amplifierInfo,multiclampIDs)

N = numel(amplifierInfo);

demoMode = false;

for ii = 1:N
    if strcmp(amplifierInfo(ii).name(end-3:end),'Demo') || ...
            strcmp(amplifierInfo(ii).name(end-3:end-1),'COM')
        % The amplifiers are in "demo mode" and/or a Multiclamp 700A is in
        % the mix
        demoMode = true;
    end
end

if demoMode % one or more amplifiers is in demo mode or a 700A is present
    [~,y] = sort(multiclampIDs);  % just use ID number because the 700A 
                                  % doesn't return a meaningful serial number
else
    serialNumber = zeros(N,1);
    for jj= 1:N
        name = amplifierInfo(jj).name;
        foo = strfind(name,'_');
        name(foo(2)+1:end)
        serialStr = name(foo(2)+1:end);
        serialNumber(jj) = str2double(serialStr);
    end
    [~,y] = sort(serialNumber);
end

        
        
    
    