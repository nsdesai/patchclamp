function [] = updateoutputs(MainApp)
% function [] = updateoutputs(MainApp)
%
% Whenever the "update outputs" button of the main GUI is pressed, this
% function reads the time, duration, and amplitude fields; generates
% output traces; and saves these in the global variable outputData. It also
% reads the period, repetitions, duration, and shuffle fields.
%
% INPUTS
% MainApp:       handle to the LCSMS_patch_clamp GUI

global DAQPARS outputData


% BASIC PROPERTIES:
% sample rate, period, shuffle, repetitions, duration (of recording)
sampleRate = str2double(MainApp.sampleRateDropDown.Value);
dt = 1000/sampleRate; % time step in milliseconds
p = getoutputvalues(MainApp); % get output values from the DAQ figure
DAQPARS.period = p.period; % period in milliseconds
DAQPARS.shuffle = p.shuffle; % shuffle order of output waveforms
DAQPARS.repetitions = p.repetitions; % number of repetitions
DAQPARS.duration = p.duration; % duration of each recording sweep

% CHECK FOR ERRORS/CONFLICTS IN EACH LINE
% go through each of the selected output lines one by one.
% discard (lineOff) empty or incomplete lines
lineOff = [];
steps = ones(numel(p.activeLines),3);
for iCount = 1:numel(p.activeLines)
    
    % every output line has a time, a duration, and an amplitude.
    %
    % time is the starting time of the stimulus (msec), duration is how 
    % long the stimulus lasts (msec), amplitude is the voltage (mV, voltage
    % step, field potential, off) or current (pA, current clamp) amplitude
    % or waveform.
    %
    % all of the fields can be vectors (e.g., 10:20:60 = [10, 30, 50]).
    % amplitude can also be an expression (e.g., ...
    % 3*sin(2*pi*100*(t/1000) + pi/2) - t/1000
    %
    timeLine = transpose(str2num(p.outputStr(iCount).time));
    durationLine = str2num(p.outputStr(iCount).duration);
    amplitudeLine = str2num(p.outputStr(iCount).amplitude);
    if isempty(timeLine) || isempty(durationLine)
        lineOff(end+1) = iCount; %#ok<*AGROW>
        continue
    end    
    % time can be a row vector (one continuous output) or a column vector 
    % (several outputs spaced by the period). duration and time are column
    % vectors only
    durationLine = durationLine(:);
    amplitudeLine = amplitudeLine(:);
    sizeOfTime = size(timeLine);
    sizeOfDuration = size(durationLine);
    sizeOfAmplitude = size(amplitudeLine);
    steps(iCount,:) = ...
        [sizeOfTime(2), sizeOfDuration(1), sizeOfAmplitude(1)];   
    if numel(find(steps(iCount,:)>1)) > 1
        lineOff(end+1) = iCount;
        continue
    end 
end
p.activeLines(lineOff) = [];
p.buttons(lineOff) = 0;
p.outputStr(lineOff) = [];
steps(lineOff,:) = [];


% CHECK FOR ERRORS/CONFLICTS BETWEEN LINES
% make sure that the number of steps is the same for all lines
[~,y] = find(steps>1);
foo = numel(unique(y));
if foo == 0
    stepsNo = 1;
else
    if foo>1
        error('Only one type of field can have multiple steps')
    else
        y = unique(y);
        boo = steps(:,y);
        boo = boo(boo>1);
        stepsNo = unique(boo);
        if numel(stepsNo)>1
            error('Unique number of steps per line')
        end
    end
end


% CREATE OUTPUTS
nSamples= round(p.duration/dt);
DAQPARS.outputChannels = find(sum(p.buttons,1));
outputs = zeros(numel(p.activeLines),nSamples,stepsNo);
for jCount = 1:numel(p.activeLines)
    nSteps = max(steps(jCount,:));
    timeLine = transpose(str2num(p.outputStr(jCount).time)); %#ok<*ST2NM>
    durationLine = str2num(p.outputStr(jCount).duration);
    amplitude = p.outputStr(jCount).amplitude;
    amplitudeLine = str2num(amplitude);

    isExpression = false; isFILE = false; isVAR = false; %#ok<NASGU>
    
    % (isExpression==true) means that a function of time, a MAT file, a 
    % text file, or a variable in memory, rather than a scaler or vector,
    % was written in the amplitude field.
    isExpression = isempty(str2num(amplitude));

    % (isFILE==true) means that that a MAT or text filewas written in the
    % amplitude field.
    isFILE = contains(amplitude,'.mat') || ...
        contains(amplitude,'.txt');
        
    % (isVAR==true) means that a variable in memory was written in the
    % amplitude field
    if ~contains(amplitude,'(t') && ~isFILE
        [isVAR,stimulus] = checkworkspaceforvariable(amplitude);
    end
    
    if isempty(timeLine) || isempty(durationLine) || ...
            (~isExpression && isempty(amplitudeLine))
        continue
    end

    if nSteps == 1          % no fields have multiple steps
        
        if isExpression 
            t = 0:dt:durationLine-dt;
            stimulusLength = round(durationLine/dt);
            N = numel(t);
            if isFILE
                stimulus = readstimulusfromfile(amplitude,N);
            elseif isVAR
                % stimulus already returned by checkworkspaceforvariable
                if N < numel(stimulus)
                    stimulus = stimulus(1:N);
                end
            else % evaluating a function
                t = t/1000; % in Matlab functions, t must always be in seconds and not milliseconds                
                fStr = ['@(t) ',amplitude];
                myFunc = str2func(fStr);
                stimulus = myFunc(t);
            end
            stimulus = stimulus(:);
            for mCount = 1:numel(timeLine)
                startSample = round(timeLine(mCount)/dt);
                startSample = max(1,startSample);
                b = squeeze(outputs(jCount,startSample:...
                    startSample+stimulusLength-1,:));
                if size(b,2)>size(b,1)
                    b = b';
                end
                if size(stimulus,2)>size(stimulus,1)
                    stimulus = stimulus';
                end
                outputs(jCount,startSample:...
                    startSample+stimulusLength-1,:) = ...
                    b + ...
                    repmat(stimulus,1,stepsNo);
            end
        else
            amplitude = str2num(p.outputStr(jCount).amplitude);
            outputTemp = zeros(nSamples,1);
            stimulusLength = round(durationLine/dt);
            for mCount = 1:numel(timeLine)
                startSample = round(timeLine(mCount)/dt);
                startSample = max(1,startSample);
                outputTemp(startSample:startSample+stimulusLength-1) = ...
                    outputTemp(startSample:startSample+stimulusLength-1)...
                    + 1;
            end
            outputs(jCount,:,:) ...
                = repmat(outputTemp,1,stepsNo)*amplitude(1);
        end
        
    else                    % one field has multiple steps
        
        multipleFields = {'time','duration','amplitude'};
        multipleField = multipleFields{y};
        timeStepsNo = size(timeLine,1);
        switch multipleField
            case 'time'
                durationLine = repmat(durationLine,nSteps,1);
                amplitudeLine = repmat(amplitudeLine,nSteps,1);
            case 'duration'
                timeLine = repmat(timeLine,1,nSteps);
                amplitudeLine = repmat(amplitudeLine,nSteps,1);
            case 'amplitude'
                timeLine = repmat(timeLine,1,nSteps);
                durationLine = repmat(durationLine,nSteps,1);
        end

        if isExpression
            
            for kCount = 1:stepsNo
                t = 0:dt:durationLine(kCount)-dt;
                stimulusLength = round(durationLine(kCount)/dt);
                N = numel(t);
                if isFILE
                    stimulus = readstimulusfromfile(amplitude,N);
                elseif isVAR
                    % stimulus already returned by checkworkspaceforvariable
                    if N < numel(stimulus)
                        stimulus = stimulus(1:N);
                    end
                else
                    t = t/1000; % in Matlab functions, t must always be in seconds and not milliseconds
                    fStr = ['@(t) ',amplitude];
                    myFunc = str2func(fStr);
                    stimulus = myFunc(t);
                end
                startSample = round(timeLine(kCount)/dt);
                startSample = max(1,startSample);
                outputs(jCount,...
                    startSample:startSample+stimulusLength-1,kCount) = ...
                    outputs(jCount,...
                    startSample:startSample+stimulusLength-1,kCount) + ...
                    stimulus;
            end
            
        else
            
            for kCount = 1:stepsNo
                outputTemp = zeros(nSamples,1);
                stimulusLength = round(durationLine(kCount)/dt);
                for mCount = 1:timeStepsNo
                    startSample = ...
                        round(timeLine(kCount*timeStepsNo-timeStepsNo+...
                        mCount)/dt);
                    startSample = max(1,startSample);
                    outputTemp(startSample:startSample + ...
                        stimulusLength-1) = ...
                        outputTemp(startSample:startSample + ...
                        stimulusLength-1) + 1;
                end
                outputs(jCount,:,kCount) ...
                    = outputTemp*amplitudeLine(kCount);
            end
        end
        
    end
    
end


% UPDATE DAQPARS AND WRITE OUTPUTDATA
DAQPARS.stepsNo = stepsNo;
DAQPARS.outputChannels = find(sum(p.buttons,1));
outputData = zeros(nSamples,stepsNo,numel(DAQPARS.outputChannels));
ii=1;
for lCount = DAQPARS.outputChannels
    lines = p.buttons(p.activeLines,lCount);
    foo = outputs(lines,:,:);
    foo = squeeze(sum(foo,1));
    if isvector(foo), foo = foo(:); end
    if lCount>4 % digital channels (5-8) are limited to 0 or 1
        foo(find(foo)) = 1; %#ok<FNDSB>
    end
    outputData(:,:,ii) = foo;
    ii = ii + 1;
end
if ~isempty(outputData)
    outputData(end,:,:) = 0;  %%% final zero
end


% DISPLAY OPTIONS FOR OUTPUT WINDOW
outputDisplayOptions = {'all active'};
for mCount = DAQPARS.outputChannels
    if mCount<5 % analog outputs
        outputDisplayOptions(end+1,:) = {['analog ',num2str(mCount)]};
    else % digital outputs
        outputDisplayOptions(end+1,:) = {['digital ',num2str(mCount)]};
    end
end
MainApp.channelstodisplayDropDown.Items = outputDisplayOptions;
MainApp.channelstodisplayDropDown.Value = 'all active';


% ONE LAST CHECK FOR AN ERROR
if isempty(outputData)
    outputData = zeros(nSamples,1);
    DAQPARS.outputChannels = 1;
end


plotoutputs     % plot the outputData in the output window of the GUI
