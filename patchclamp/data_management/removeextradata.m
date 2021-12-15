function [] = removeextradata(tasksExecuted)
% function [] = removeextradata(tasksExecuted)
%
% If user interrupts a recording in progress, we clean up the data file on
% disk by getting rid of the parts of inputData that were padded with
% zeros.
%
% INPUTS
% tasksExecuted:    number of task executed by recording timer(niTimer)

global DAQPARS

descriptor = DAQPARS.MainApp.descriptorEditField.Value;
if isempty(descriptor)
    fName = [DAQPARS.fileName,'.mat'];
else
    fName = [DAQPARS.fileName,'_',descriptor,'.mat'];
end
load([DAQPARS.saveDirectory,fName]) %#ok<LOAD>
inputData = squeeze(inputData(:,1:tasksExecuted,:)); %#ok<*NODEF>
DAQPARS.orderOfSteps = DAQPARS.orderOfSteps(1:tasksExecuted);
Pars.orderOfSteps = DAQPARS.orderOfSteps;
save([DAQPARS.saveDirectory,fName],...
    'outputData','inputData','Pars') %#ok<*USENS>