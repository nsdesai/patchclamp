function daqBoardOkay = ...
    checkdaqboard(daqBoardInfo)
% function [daqBoardOkay] = ...
%   checkdaqboard(daqBoardInfo,daqBoardIdx,daqBoardChannels)
%
% Checks that the National Instruments board is present and can be
% initialized.
%
% INPUTS
% daqBoardInfo:     information about the specified National Instruments
%                   board
% daqBoardIdx:      index to the National Instruments board
% daqBoardChannels: input/output channels to use
%
%
% OUTPUTS
% daqBoardOkay:     true or false   (IO board)

boardID = daqBoardInfo.ID;
boardModel = daqBoardInfo.Model;

d = daqlist("ni");
IDs = d{:,1};
idx = strcmp(IDs,boardID); % index to ID
model = d{idx,3};
if strcmp(model,boardModel)
    daqBoardOkay = true;
else
    daqBoardOkay = false;
    disp('Board specified in hardwareConfiguration was not found. Opening hardware GUI ...')
end



    