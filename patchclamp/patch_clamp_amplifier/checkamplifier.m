function [amplifierOkay] = checkamplifier(amplifierInfo,amplifierIdx)
% function [amplifierOkay] = checkamplifier(amplifierInfo,amplifierIdx)
%
% Checks that the Multiclamp amplifiers specified by the 
% hardwareConfiguration file are present.
%
% INPUTS
% amplifierInfo:    information about amplifier settings,
%                   including input/output scaling (e.g., V/pA, V/mV),
%                   for the four analog inputs (channels 1-4) that can
%                   be used for patch clamp
% amplifierIdx:     indices to the amplifier settings for each 
%                   channel
%
% OUTPUTS
% amplifierOkay:     true or false   (amplifier)
global DAQPARS

amplifierOkay = true;

MulticlampTelegraph('start')
detectedIDs = MulticlampTelegraph('getAllElectrodeIDS');
MulticlampTelegraph('stop')

nChannels = numel(amplifierIdx);

for ii = 1:nChannels
    
    idx = amplifierIdx(ii);
    specifiedID = amplifierInfo(idx).ID;
    if idx > 4, continue, end       % ignore manual settings
    sStr = ['statusDropDown_',num2str(ii)];
    eStr = ['enableSwitch_',num2str(ii)];
    if ismember(specifiedID, detectedIDs)
        if ii==1
            DAQPARS.MainApp.(eStr).Value = 'enable'; % we assume channel 1 is always in use
            DAQPARS.MainApp.(sStr).Enable = true;
        else
            DAQPARS.MainApp.(eStr).Value = 'disable'; % other channels might not be in use
            DAQPARS.MainApp.(sStr).Value = 'off';
            DAQPARS.MainApp.(sStr).Enable = false;
        end
        DAQPARS.MainApp.(eStr).Enable = true;
        disp(' ')
        disp(['Channel ',num2str(idx),' is CONNECTED to an active Multiclamp amplifier and is ready to use.'])
        disp(' ')
    else
        DAQPARS.MainApp.(sStr).Value = 'off';
        DAQPARS.MainApp.(sStr).Enable = false;
        DAQPARS.MainApp.(eStr).Value = 'disable';
        DAQPARS.MainApp.(eStr).Enable = false;
        disp(' ')
        disp(['Channel ',num2str(idx),' is NOT CONNECTED to an active Multiclamp amplifier and has been disabled.'])
        disp('If you wish to use it, turn on the associated Multiclamp amplifier, open the Commander window, and again type patchclamp at the Matlab command line.')
        disp(' ')
    end
    
end

    
