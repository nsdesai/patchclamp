function s = nidaqboard
% function s = nidaqboard
% 
% Create a data acquisition session and add input/output channels
%
% OUTPUTS
% s:        data acquisition object containing analog input and output
%           channels

global DAQPARS

s = daq("ni");

s.Rate = DAQPARS.sampleRate;

idx = DAQPARS.daqBoardIdx; % identifier of the NIDAQ board to use

aiChannels = DAQPARS.daqBoardChannels(1,DAQPARS.inputChannels);
addinput(s,DAQPARS.daqBoardInfo(idx).ID,aiChannels,"Voltage")
 
for ii = DAQPARS.outputChannels
    
    if ii<5     % analog
        aoChannel = char(DAQPARS.daqBoardChannels(2,ii));        
        addoutput(s,DAQPARS.daqBoardInfo(idx).ID,aoChannel,'Voltage');
    else        % digital
        dioChannel = char(DAQPARS.daqBoardChannels(2,ii));
        addoutput(s,DAQPARS.daqBoardInfo(idx).ID,dioChannel,'Digital');
    end
    
end

