function p = getoutputvalues(MainApp)
% function p = getoutputvalues(MainApp)
%
% Read the values in the output panel of the DAQ figure (lower right 
% panel). This includes repetitions, period, duration, shuffle (yes or no),
% and the time/duration/amplitude fields of the 12 output lines. We also
% make sure here that the period is longer than the recording duration  
% and the duration at least as long as the stimuli; we adjust them if not.

nLines = 12;                         % the GUI has 12 lines at present
minTimeBetweenTraces = 500;          % at least these many milliseconds

p.repetitions = MainApp.repetitionsEditField.Value;
p.period = MainApp.periodEditField.Value;
p.duration = MainApp.durationEditField.Value;
p.shuffle = MainApp.shuffleCheckBox.Value;

% check which channel buttons the user has selected; this is returned in
% the field activeLines (0 = not selected, 1 = selected)
p.buttons = MainApp.UIOutputChannels.Data;
p.activeLines = find(sum(p.buttons,2))'; % row vector

outputFields = {'time','duration','amplitude'};
outputStr = cell(nLines,numel(outputFields));
duration = p.duration;
if ~isempty(p.activeLines)
    for kCount = p.activeLines
        for lCount = 1:numel(outputFields)
            outputStr{kCount,lCount} = MainApp.UIOutputData.Data{kCount,lCount};
            if isempty(outputStr{kCount,lCount})
                outputStr{kCount,lCount} = '0';
            end
        end
        maxRecordingDuration = max(str2num(outputStr{kCount,1})) + ...
            max(str2num(outputStr{kCount,2})); %#ok<*ST2NM>  %% we do want str2num here, not str2double
        if ~isempty(maxRecordingDuration)
            duration = max(duration,maxRecordingDuration);
        end
    end
    p.duration = duration;  % in case stimuli are longer than stated duration
end
padding = rem(p.duration,100); % durations must always be integer multiples of 100 msec
if padding
    p.duration = p.duration + 100 - padding;
end
MainApp.durationEditField.Value = p.duration;

if (p.duration+minTimeBetweenTraces)>p.period          % period must be longer than duration
    p.period = p.duration + minTimeBetweenTraces;
    MainApp.periodEditField.Value = p.period;
end

foo = cell2struct(outputStr,outputFields,2);
p.outputStr = foo(p.activeLines);


