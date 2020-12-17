function [] = startrecording
% function [] = startrecording
%
% This is the function called when the user presses the start button on the
% DAQ figure. The outputs were previously created (updateoutputs.m); here
% they are placed in the order in which they will be used. Space is
% preallocated for the inputs to be recorded. The scaling numbers for
% inputs and outputs are set, using the amplifier's scaling (mV/V or pA/V)
% and the gain specified in the DAQ figure. Display plans are readied. A 
% data acquisition object is created. And finally the recording commences.
%
% Data acquisition uses a timer function ("niTimer"). If, for example, the
% output is a family of N current steps (and the inputs a corresponding
% family of voltage responses), the timer will execute N times.
%


global DAQPARS outputData inputData
global plottingCounter stopBackground recordingCounter

app = DAQPARS.MainApp;
dt = 1000/DAQPARS.sampleRate;

if isempty(stopBackground) || stopBackground==1 
    stopBackground = 0;
else
    stopBackground = 1;
    return
end


% if the user presses the stop button, execution is halted by eliminating
% the timer, which triggers the timer's StopFcn.
if ~isempty(timerfind('Tag','niTimer'))
    stop(timerfind('Tag','niTimer'))
    return
end


% make sure that at least one input channel has been selected
channelOn = ~strcmp(DAQPARS.channelStatus,'off');
DAQPARS.inputChannels = find(channelOn);
if isempty(DAQPARS.inputChannels)
    warndlg('At least one input channel must be active',...
        'Choose an input channel')
    return
end


% outputData is in the form (samples x steps x channels)
nSteps = size(outputData,2);
nTotalSteps = nSteps * DAQPARS.repetitions;
DAQPARS.orderOfSteps = repmat(1:nSteps,1,DAQPARS.repetitions);
if DAQPARS.shuffle
    for iCount = 1:DAQPARS.repetitions
        DAQPARS.orderOfSteps(iCount*nSteps-nSteps+1:iCount*nSteps) = ...
            randperm(nSteps);
    end
end


% preallocate memory for the input data
inputData = zeros(size(outputData,1),nTotalSteps,...
    numel(DAQPARS.inputChannels));      


% get the numbers with which to scale the outputs and the inputs so that
% the currents are in pA and the voltages in mV
outputGains = ones(1,DAQPARS.nChannels);
inputGains = ones(1,DAQPARS.nChannels);
ampInfo = DAQPARS.amplifierInfo(DAQPARS.amplifierIdx);
isPressure = zeros(1,DAQPARS.nChannels);
for mCount = 1:DAQPARS.nChannels
    statusChannel = DAQPARS.channelStatus{mCount};
    ampInfoChannel = ampInfo(mCount);
    switch statusChannel
        case 'off'
            outputGains(mCount) = 1;
            inputGains(mCount) = 1;
        case 'voltage clamp'
            outputGains(mCount) = ampInfoChannel.outputScalingVoltageClamp;
            inputGains(mCount) = ...
                DAQPARS.channelGain(mCount)/ampInfoChannel.inputScalingVoltageClamp;
        case 'current clamp'
            outputGains(mCount) = ampInfoChannel.outputScalingCurrentClamp;
            inputGains(mCount) = ...
                DAQPARS.channelGain(mCount)/ampInfoChannel.inputScalingCurrentClamp;
        case 'I = 0'
            outputGains(mCount) = Inf;
            inputGains(mCount) = ...
                DAQPARS.channelGain(mCount)/ampInfoChannel.inputScalingCurrentClamp;            
        case 'field potential'
            outputGains(mCount) = 1;
            inputGains(mCount) = DAQPARS.channelGain(mCount)/1000;  
        case 'pressure'
            outputGains(mCount) = 1;
            inputGains(mCount) = 1;
            isPressure(mCount) = 1;
        case 'conductance'
            outputGains(mCount) = 1;
            inputGains(mCount) = 1;
    end
end
outputGains = outputGains(DAQPARS.outputChannels);
inputGains = inputGains(DAQPARS.inputChannels);
isPressure = isPressure(DAQPARS.inputChannels);


% the user selects what is to be displayed in the input windows 
set(app.UIInputAxes1,'NextPlot','replacechildren')
set(app.UIInputAxes2,'NextPlot','replacechildren')
displayButtons = app.UIPlottingChannels.Data;
load('plottingColors.mat','colors')  % this is in the parameters_and_gui folder


% get input windows ready
ax1 = ones(numel(DAQPARS.inputChannels),1);
for iCount = 1:numel(DAQPARS.inputChannels)
    foo = find(displayButtons(:,...
        DAQPARS.inputChannels(iCount)),1); %#ok<*AGROW>
    if isempty(foo)
        ax1(iCount) = 1;
        DAQPARS.MainApp.UIPlottingChannels.Data(1,DAQPARS.inputChannels(iCount)) = true;
    else
        ax1(iCount) = foo;
    end
end
[ax,popup] = chooseaxes(ax1);


% get ready to go
set(app.startButton,'Text','stop')
if DAQPARS.repetitions > 1
    progressFigure = uifigure;
    progressFigure.Position = [150 50 400 80];
    progressFigure.Name = 'PROGRESS';
    progressDialog = uiprogressdlg(progressFigure,'Title','Acquiring ...');
    progressDialog.Value = 0;
else
    progressFigure = [];
    progressDialog = [];
end
drawnow limitrate


% create the data acquisition object
daqreset
daqObj = nidaqboard;


% get mouse and recording info
DAQPARS.notes = DAQPARS.MainApp.notesTextArea.Value;
DAQPARS.mouseid = DAQPARS.MainApp.mouseidEditField.Value;
DAQPARS.DOB = DAQPARS.MainApp.DOBDatePicker.Value;
DAQPARS.sex = DAQPARS.MainApp.sexSwitch.Value;


% posthoc analysis: yes or no
recordingMode = zeros(DAQPARS.nChannels,1);
for ii = 1:DAQPARS.nChannels
    switch DAQPARS.channelStatus{ii}
        case 'voltage clamp'
            recordingMode(ii) = 1;
        case 'current clamp'
            recordingMode(ii) = 2;
        case 'field potential'
            recordingMode(ii) = 3;
        case 'I=0'
            recordingMode(ii) = 4;
    end
end
if app.donotcheckButton.Value && strcmp(app.otheranalysesDropDown.Value,'none')
    DAQPARS.posthoc = false;
elseif app.checkButton.Value
    DAQPARS.posthoc = true;
    foo = recordingMode;
    foo(foo>2) = [];
    foo(foo==0) = [];
    if isempty(foo) || nnz(app.UIStability.Data)==0
        disp('No stability analysis.');
        disp('Either no channels were selected or none are in voltage/current clamp.')
        DAQPARS.posthoc = false;
    else
        startTime = round(app.beginningStabilityEditField.Value/dt);
        stopTime = round(app.endStabilityEditField.Value/dt);
        deflectionOutput = ones(DAQPARS.nChannels,1);
        try
            for nn = 1:DAQPARS.nChannels
                foo = DAQPARS.channelStatus{nn};               
                if strcmp(foo,'voltage clamp') || strcmp(foo,'current clamp')
                    if app.UIStability.Data(nn)
                        activeNo = DAQPARS.outputChannels==nn;
                        output2 = outputData(startTime:stopTime,...
                            1,activeNo);
                        dOutput = diff(output2);
                        boo = find(dOutput);
                        first = boo(1);
                        second = boo(2);
                        deflectionOutput(nn) = abs(output2(first+5)-output2(first-5));
                    end 
                end
            end
            DAQPARS.stability.deflectionOutput = deflectionOutput;
            DAQPARS.stability.first = first;
            DAQPARS.stability.second = second;
        catch
            DAQPARS.posthoc = false;
            disp('Make sure the outputs include a step in the stability window.');
        end
    end
end

if ~strcmp(app.otheranalysesDropDown.Value,'none')
    DAQPARS.posthoc = true;
    if nnz(recordingMode) == 0
        disp('No other analysis.')
        disp('No channels selected.');
        DAQPARS.posthoc = false;
    end
end


recordingCounter = 1;
DAQPARS.time = now;
DAQPARS.triggerTime = [];
if DAQPARS.duration <= 2000     % user timer and startForeground for short sweeps
    cla(ax(1)); cla(ax(2));
    hold(ax(1),'on'); hold(ax(2),'on')
    for iCount = 1:numel(DAQPARS.inputChannels)
        plotHandle(iCount) = plot(ax(ax1(iCount)), ...
            dt:dt:DAQPARS.duration,...
            NaN(length(outputData),1),...
            'color',colors(DAQPARS.inputChannels(iCount),:)); %#ok<*SAGROW,*NASGU>
    end
    hold(ax(1),'off'); hold(ax(2),'off')
    if ~popup
        xlim(ax(1),[0 DAQPARS.duration]);
        xlim(ax(2),[0 DAQPARS.duration]);
    end
    niTimer = timer('TimerFcn',...
        {@startdaq,daqObj,inputGains,outputGains,progressDialog,plotHandle,recordingMode},...
        'StopFcn',{@stopdaq,daqObj,progressDialog,progressFigure},...
        'Period',DAQPARS.period/1000,'ExecutionMode','fixedRate',...
        'BusyMode','queue','TasksToExecute',nTotalSteps,'Tag','niTimer');
    start(niTimer)
else
    t0 = clock;
    for backgroundCounter = 1:nTotalSteps
        stop(daqObj); flush(daqObj);
        cla(ax(1)); cla(ax(2));
        hold(ax(1),'on'); hold(ax(2),'on')
        for iCount = 1:numel(DAQPARS.inputChannels)
            plotHandle(iCount) = plot(ax(ax1(iCount)), ...
                dt:dt:DAQPARS.duration,...
                NaN(length(outputData),1),...
                'color',colors(DAQPARS.inputChannels(iCount),:));
        end
        hold(ax(1),'off'); hold(ax(2),'off')
        if ~popup
            xlim(ax(1),[0 DAQPARS.duration]);
            xlim(ax(2),[0 DAQPARS.duration]);
            axis 'auto y'
        end
        output1 = squeeze(outputData(:,DAQPARS.orderOfSteps(recordingCounter),:)) ...
            ./ repmat(outputGains,size(outputData,1),1);
        preload(daqObj, output1);
        N = ceil(DAQPARS.sampleRate/10); % minimum number to trigger ScansAvailableFcn
        daqObj.ScansAvailableFcnCount = N;
        daqObj.ScansAvailableFcn = @(src,evt) plotinputs(src,evt,inputGains,plotHandle);
        plotoutputs(recordingCounter)
        plottingCounter = 1;
        triggerTime = now;
        start(daqObj)
        nTotalScans = length(output1);
        while daqObj.NumScansAcquired<nTotalScans
            if stopBackground
                break
            end
            drawnow limitrate
        end
        DAQPARS.triggerTime(backgroundCounter) = triggerTime;
        pause(0.2) % give plotinputs time to finish
        input1 = output1;
        for jCount = 1:numel(DAQPARS.inputChannels)
            input1(:,jCount) = get(plotHandle(jCount),'YData');
        end
        savedata(input1,recordingCounter)
        try
            if DAQPARS.posthoc == true
                posthocanalysis(input1,recordingMode);
            end
        catch ME
            DAQPARS.stability.ME = ME;
        end
        if backgroundCounter < nTotalSteps
            while etime(clock,t0)<(DAQPARS.period/1000)
                if stopBackground
                    break %#ok<*UNRCH>
                end
                drawnow limitrate
            end
            t0 = clock;
        else
            while daqObj.Running
                if stopBackground
                    break
                end
                drawnow limitrate
            end
        end
        if stopBackground
            break
        end
        while (daqObj.NumScansQueued>0), drawnow limitrate; end 
        while (daqObj.NumScansAvailable>0), drawnow limitrate; end
        if ~isempty(progressDialog)
            progressDialog.Value = recordingCounter / nTotalSteps;
        end
        recordingCounter = recordingCounter + 1;
    end
    stop(daqObj)
    delete(daqObj)
    if stopBackground
        if backgroundCounter < nTotalSteps
            removeextradata(backgroundCounter);
        end
    end
    if ~isempty(progressFigure)
        close(progressDialog);
        close(progressFigure);
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
    set(DAQPARS.MainApp.startButton,'Text','start')
    app.Recording = false;
end

stopBackground = [];


