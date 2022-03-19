function [] = startdaq(obj,~,inputGains,outputGains,...
    progressDialog,plotHandle,recordingMode,completedSweepsField)
% function [] = startdaq(obj,~,inputGains,outputGains,...
%   displayButtons,progressDialog)
%
% Function called by recording timer (niTimer) on each execution step. The 
% output data are queued to the board, simultaneous output and input are
% executed, results (input1) are plotted and saved.
%
% INPUTS
% obj,event:        object and event for timer
% inputGains:       how to scale inputs given state of amplifier
% outputGains:      how to scale outputs given state of amplifier
% progressDialog:   handle to progress dialog
% plotHandle:       handle to the input windows for plotting
% recordingMode:    array that indicates recording mode of each channel

global DAQPARS outputData recordingCounter

stop(DAQPARS.daqObj); flush(DAQPARS.daqObj)
output1= squeeze(outputData(:,DAQPARS.orderOfSteps(recordingCounter),:)) ...
    ./ repmat(outputGains,size(outputData,1),1);
[input1,~,triggerTime] = readwrite(DAQPARS.daqObj,output1,"OutputFormat","Matrix");
input1 = input1 ./ repmat(inputGains,size(input1,1),1);
for iCount = 1:size(input1,2)
    set(plotHandle(iCount),'YData',input1(:,iCount))
end
DAQPARS.triggerTime(obj.TasksExecuted) = triggerTime;
savedata(input1,recordingCounter)
plotoutputs(recordingCounter)
progressSoFar = recordingCounter / obj.TasksToExecute;
if ~isempty(progressDialog)
    progressDialog.Value = progressSoFar;
    progressDialog.Message = ['Completed ',num2str(recordingCounter),' of ',num2str(obj.TasksToExecute)];
    if ~isempty(completedSweepsField)
        completedSweepsField.Value = recordingCounter;
    end
end
recordingCounter = recordingCounter + 1;
try
    if DAQPARS.posthoc == true
        posthocanalysis(input1,recordingMode);
    end
catch ME
    DAQPARS.stability.ME = ME;
end

