function [] = writemulticlamp(~)
global DAQPARS

oldFolder = cd([DAQPARS.daqFolder,'\patch_clamp_amplifier\MulticlampControl\Debug']);
cmdPreamble = 'MulticlampControl.exe ';


status = DAQPARS.channelStatus;
gain = DAQPARS.channelGain;
holding = DAQPARS.channelHolding;

hWait = waitbar(0.2,'Please wait as we update amplifiers ...');

for ii = 1:numel(DAQPARS.amplifierIdx)
    idx = DAQPARS.amplifierIdx(ii);
    if idx > 4, continue, end   % ignore manual settings
    
    % name will be like MC700A_ch1_COM3 or MC700B_ch2_38482
    % the last entry is the COM port for 700A and the serial
    % number of 700B (in demo mode, the latter is "Demo")
    name = DAQPARS.amplifierInfo(idx).name;
    % model = '0' means 700A, model = '1' means 700B
    if strcmp(name(6),'B'), model = '1'; else model = '0'; end
    if strcmp(model,'0')
        amplifierID = name(15);
    else
        amplifierID = name(12:end);
    end
    channelID = name(10);
    
    switch status{ii}
        case 'voltage clamp'
            
            cmd = [cmdPreamble, model,' ', amplifierID,' ',...
                channelID,' 3 ',num2str(gain(ii)),' ', ...
                num2str(holding(ii))];
            
        case 'current clamp'
            
            cmd = [cmdPreamble, model,' ', amplifierID,' ',...
                channelID,' 2 ',num2str(gain(ii)),...
                ' 10000 10000 ',num2str(holding(ii))];
            
        case 'I=0'
            
            cmd = [cmdPreamble, model,' ',amplifierID,' ',...
                channelID,' 6 ',num2str(gain(ii))];
            
        otherwise
            
            continue
            
    end
    
    system(cmd);
    
    waitbar(ii*0.2+0.2,hWait,'Please wait as we update amplifiers ...');
    
end

close(hWait)
cd(oldFolder)
DAQPARS.multiclampHolding = DAQPARS.channelHolding;
