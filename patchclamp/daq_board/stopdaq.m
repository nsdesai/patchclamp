function [] = stopdaq(obj,event,daqObj,progressDialog,progressFigure)  %#ok<INUSL>
% function [] = stopdaq(obj,event,daqObj)
%
% Function called by recording timer (niTimer) when it stops. Cleans up by
% deleting the data acquisition object (daqObj) and the timer object, 
% discarding zeros from the saved data, and incrementing the trial number.
%
% INPUTS
% obj,event:        timer object and event
% daqObj:           data acquisition object created by nidaqboard
% progressDialog:   progress dialog within progress figure
% progressFigure:   progress figure

global DAQPARS inputData stopBackground

tasksExecuted = obj.TasksExecuted;
tasksToExecute = obj.TasksToExecute;
delete(obj)
stop(daqObj)
delete(daqObj)
inputData = [];
if tasksExecuted < tasksToExecute
    removeextradata(tasksExecuted)
end
set(DAQPARS.MainApp.startButton,'Text','start')
if ~isempty(progressFigure)
    close(progressDialog)
    close(progressFigure)
end
drawnow
if DAQPARS.MainApp.savedataCheckBox.Value 
    newexperiment('next trial')
else % move data to temp folder and append time
    descriptor = DAQPARS.MainApp.descriptorEditField.Value;
    if isempty(descriptor)
        fName = [DAQPARS.fileName,'.mat'];
    else
        fName = [DAQPARS.fileName,'_',descriptor,'.mat'];
    end
    fName1 = [DAQPARS.saveDirectory,fName];
    tempName = [DAQPARS.saveDirectory,'temp\',datestr(now,30),'_',fName];
    movefile(fName1, tempName)
end 
stopBackground = [];
