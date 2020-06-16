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

amplifierOkay = true;

MulticlampTelegraph('start')
detectedIDs = MulticlampTelegraph('getAllElectrodeIDS');
MulticlampTelegraph('stop')

nChannels = numel(amplifierIdx);


for ii = 1:nChannels
    
    idx = amplifierIdx(ii);
    specifiedID = amplifierInfo(idx).ID;
    if idx > 4, continue, end       % ignore manual settings
    if ~ismember(specifiedID, detectedIDs)
        amplifierOkay = false;
        disp('Specified Multiclamp amplifier channels were not detected. ...')
    end
    
end

if ~amplifierOkay
    answer = ...
        questdlg('Choices: (1) open Multiclamp Commander windows and then press RETRY or (2) SELECT a new hardware configuration.',...
        'Multiclamp amplifiers not detected','Retry',...
        'Select hardware','Retry');
    if strcmp(answer,'Retry')
        amplifierOkay = checkamplifier(amplifierInfo,amplifierIdx);
    end
end
        
    
    
