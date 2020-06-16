function [] = plotoutputs(recordingCounter)
% function [] = plotoutputs(recordingCounter)
% 
% Plots the output data in the output window of the DAQ figure. If a
% recording is in progress, makes the waveform for the current output
% thicker; the current output is indexed by recordingCounter.
%
% INPUTS
% recordingCounter:         number of (steps * repetitions) that have been
%                           executed so far

global DAQPARS outputData

app = DAQPARS.MainApp;
ax = app.UIOutputAxes; cla(ax);
dt = 1000/DAQPARS.sampleRate;  % time step in milliseconds (typically 0.1)
t = (1:length(outputData))*dt - dt; 

value = app.channelstodisplayDropDown.Value;

if strcmp(value,'all active')
    displayChannels = DAQPARS.outputChannels;
else
    displayChannels = str2double(value(end));
end

load('plottingColors.mat','colors')  % this is in the parameters_and_gui folder
for iCount = 1:numel(displayChannels)
    channelNo = displayChannels(iCount);
    color = colors(channelNo,:);
    activeNo = DAQPARS.outputChannels==channelNo;
    plot(ax,t,outputData(:,:,activeNo)+DAQPARS.channelHolding(channelNo),...
        'color',color)
    if nargin
        plot(ax,t,outputData(:,DAQPARS.orderOfSteps(recordingCounter),...
            activeNo)+DAQPARS.channelHolding(channelNo),'color',color,...
            'linewidth',2)
    end
end

axis(ax,'auto')
lims = axis(ax);
yRange = lims(4)-lims(3);
ylim(ax,[lims(3)-yRange*.05 lims(4)+yRange*.05])
% app.YTickLabel = 'auto';
