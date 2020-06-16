function [] = savedata(input1,recordingCounter)
% function [] = savedata(inputTemp,recordingCounter)
%
% Saves data to a file
%
% INPUTS
% input1:                   input data to save
% recordingCounter:         how many steps/repetitions have been executed
%                           so far 

global DAQPARS outputData inputData

inputData(:,recordingCounter,:) = input1;
Pars = rmfield(DAQPARS,'MainApp');
descriptor = DAQPARS.MainApp.descriptorEditField.Value;
if isempty(descriptor)
    fName = [DAQPARS.fileName,'.mat'];
else
    fName = [DAQPARS.fileName,'_',descriptor,'.mat'];
end
save([DAQPARS.saveDirectory,fName],...
    'outputData','inputData','Pars')
