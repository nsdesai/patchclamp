function s = nidaqboard
% function s = nidaqboard
% 
% Create a data acquisition session and add input/output channels
%
% OUTPUTS
% s:        data acquisition object containing analog input, analog output,
%           and digital output channels

global DAQPARS %#ok<GVMIS> 


if isempty(DAQPARS.inputChannels)
    s = DAQPARS.daqObj;
    return
end

s = daq("ni");

s.Rate = DAQPARS.sampleRate;

aiChannels = DAQPARS.daqBoardChannels(1,DAQPARS.inputChannels);
addinput(s,DAQPARS.daqBoardInfo.ID,aiChannels,"Voltage")
 
for ii = 1:numel(DAQPARS.outputChannels)
    chan = DAQPARS.outputChannels(ii);
    if chan<5     % analog
        aoChannel = char(DAQPARS.daqBoardChannels(2,chan));       
        addoutput(s,DAQPARS.daqBoardInfo.ID,aoChannel,'Voltage');
    else        % digital
        dioChannel = char(DAQPARS.daqBoardChannels(2,chan));
        addoutput(s,DAQPARS.daqBoardInfo.ID,dioChannel,'Digital');
    end
    
end

