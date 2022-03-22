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


global DAQPARS outputData inputData %#ok<*GVMIS> 
global plottingCounter stopBackground recordingCounter

app = DAQPARS.MainApp;
dt = 1000/DAQPARS.sampleRate;

if isempty(stopBackground) || stopBackground==1 
    stopBackground = 0;
else
    stopBackground = 1;
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
multiclampSyncRequired = false;
MulticlampTelegraph('start')
for kk = 1:numel(DAQPARS.inputChannels)
    channelNo = DAQPARS.inputChannels(kk);
    channelName = DAQPARS.amplifierInfo(channelNo).name;
    if isempty(channelName) || ~strcmp(channelName(1:2),'MC')
        continue
    end
    if DAQPARS.channelHolding(channelNo) ~= DAQPARS.multiclampHolding(channelNo)
        multiclampSyncRequired = true;
        continue
    end
    ID = DAQPARS.amplifierInfo(channelNo).ID;
    chan = MulticlampTelegraph('getElectrodeState',ID);
    switch chan.OperatingMode
        case 'V-Clamp'
            if ~strcmp(DAQPARS.channelStatus{channelNo},'voltage clamp')
                multiclampSyncRequired = true;
            end
        case 'I-Clamp'
            if ~strcmp(DAQPARS.channelStatus{channelNo},'current clamp')
                multiclampSyncRequired = true;
            end
        case 'I = 0'
            if ~strcmp(DAQPARS.channelStatus{channelNo},'I=0')
                multiclampSyncRequired = true;
            end
        otherwise
            % nothing
    end
    if chan.Alpha ~= DAQPARS.channelGain(channelNo)
        multiclampSyncRequired = true;
    end
end
MulticlampTelegraph('stop')
DAQPARS.multiclampSyncRequired = multiclampSyncRequired;
if DAQPARS.multiclampSyncRequired
    pushWriteMulticlampButton(app)
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
if ~popup
    axis(ax(1),'auto')
    axis(ax(2),'auto')
    completedSweepsField = [];
    totalSweepsField = [];
end


% check if user has requested a gap-free loop of the first output
if strcmp(app.episodicDropDown.Value,'episodic')
    loopRequested = false;
else
    loopRequested = true;
end


% get ready to go
set(app.startButton,'Text','stop')
if (DAQPARS.repetitions>1) && ~loopRequested
    progressFigure = uifigure;
    progressFigure.Position = [150 50 400 120];
    progressFigure.Name = 'PROGRESS';
    progressDialog = uiprogressdlg(progressFigure,'Title','Acquiring ...');
    progressDialog.Value = 0;
    progressDialog.Message = ['Completed 0 of ',num2str(nTotalSteps)];
    if popup
        totalSweepsField = findobj('Tag','popup1_totalsweeps');
        if ~isempty(totalSweepsField)
            totalSweepsField.Value = nTotalSteps;
            completedSweepsField = findobj('Tag','popup1_completedsweeps');
            completedSweepsField.Value = 0;
        else
            totalSweepsField = [];
            completedSweepsField = [];
        end
    end
else
    progressFigure = [];
    progressDialog = [];
    totalSweepsField = [];
    completedSweepsField = [];
end
drawnow limitrate


% get mouse and recording info
DAQPARS.notes = DAQPARS.MainApp.notesTextArea.Value;
DAQPARS.mouseid = DAQPARS.MainApp.mouseidEditField.Value;
DAQPARS.DOB = DAQPARS.MainApp.DOBDatePicker.Value;
DAQPARS.sex = DAQPARS.MainApp.sexSwitch.Value;

% check that nidaq board is ready
if ~isvalid(DAQPARS.daqObj)
    DAQPARS.daqObj = nidaqboard;
end


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
if loopRequested
    progressFigure = [];
    stop(DAQPARS.daqObj); flush(DAQPARS.daqObj);
    output1 = squeeze(outputData(:,1,:)) ./ repmat(outputGains,size(outputData,1),1);
    [tempFile,fileName,triggerTime] = looprecording(ax,ax1,output1,inputGains,colors,popup);
    fclose(tempFile);
    descriptor = app.descriptorEditField.Value;
    if isempty(descriptor)
        fName = [DAQPARS.fileName,'.mat'];
    else
        fName = [DAQPARS.fileName,'_',descriptor,'.mat'];
    end
    DAQPARS.preview.fName1 = [DAQPARS.saveDirectory,fName];
    % convert bin to MAT
    % DAQPARS.preview.tempName = new MAT file (including outputData and
    % Pars)
    fid = fopen(fileName);
    inputData = fread(fid,"double");
    fclose(fid);
    N = ceil(length(inputData)/length(output1));
    outputData = repmat(outputData(:,1,:),N,1);
    outputData = outputData(1:length(inputData),:);
    Pars = rmfield(DAQPARS,{'MainApp','daqObj'});
    Pars.orderOfSteps = 1;
    Pars.repetitions = 1;
    Pars.triggerTime = triggerTime;
    if strcmp(app.saveDropDown.Value,'save data')
        newexperiment('next trial')
        save(DAQPARS.preview.fName1,'Pars','outputData','inputData')
        DAQPARS.preview.tempName = [];
    else
        foo = fileName(1:end-3);
        foo = [foo,'mat'];
        DAQPARS.preview.tempName = foo;
        save(DAQPARS.preview.tempName,'Pars','outputData','inputData')
    end
else

        warning('off','MATLAB:subscripting:noSubscriptsSpecified');
        t0 = clock;
        for backgroundCounter = 1:nTotalSteps
            stop(DAQPARS.daqObj); flush(DAQPARS.daqObj);
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
            preload(DAQPARS.daqObj, output1);
            N = ceil(DAQPARS.sampleRate/10); % minimum number to trigger ScansAvailableFcn
            DAQPARS.daqObj.ScansAvailableFcnCount = N;
            DAQPARS.daqObj.ScansAvailableFcn = @(src,evt) plotinputs(src,evt,inputGains,plotHandle);
            plotoutputs(recordingCounter)
            plottingCounter = 1;
            triggerTime = now;
            start(DAQPARS.daqObj)
            nTotalScans = length(output1);
            while DAQPARS.daqObj.NumScansAcquired<nTotalScans
                if stopBackground
                    stop(DAQPARS.daqObj)
                    break
                end
                drawnow limitrate
            end
            DAQPARS.triggerTime(backgroundCounter) = triggerTime;
            pause(0.2) % give plotinputs time to finish
            input1 = zeros(size(output1,1),numel(DAQPARS.inputChannels));
            for jCount = 1:numel(DAQPARS.inputChannels)
                input1(:,jCount) = get(plotHandle(jCount),'YData');
            end
            inputData(:,recordingCounter,:) = input1;
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
                        stop(DAQPARS.daqObj)
                        break %#ok<*UNRCH>
                    end
                    drawnow limitrate
                end
                t0 = clock;
            else
                while DAQPARS.daqObj.Running
                    if stopBackground
                        stop(DAQPARS.daqObj)
                        break
                    end
                    drawnow limitrate
                end
            end
            if stopBackground
                stop(DAQPARS.daqObj)
                break
            end
            while (DAQPARS.daqObj.NumScansQueued>0), drawnow limitrate; end
            while (DAQPARS.daqObj.NumScansAvailable>0), drawnow limitrate; end
            if ~isempty(progressDialog)
                progressDialog.Value = recordingCounter / nTotalSteps;
                progressDialog.Message = ['Completed ',num2str(recordingCounter),' of ',num2str(nTotalSteps)];
                if ~isempty(completedSweepsField)
                    completedSweepsField.Value = recordingCounter;
                end
            end
            recordingCounter = recordingCounter + 1;
            Pars = rmfield(DAQPARS,{'MainApp','daqObj'});
            Pars.orderOfSteps = Pars.orderOfSteps(1:backgroundCounter);
            descriptor = DAQPARS.MainApp.descriptorEditField.Value;
            if isempty(descriptor)
                fName = [DAQPARS.fileName,'.mat'];
            else
                fName = [DAQPARS.fileName,'_',descriptor,'.mat'];
            end
            save([DAQPARS.saveDirectory,fName],...
                'outputData','inputData','Pars','-nocompression')
        end
        Pars = rmfield(DAQPARS,{'MainApp','daqObj'});
        Pars.orderOfSteps = Pars.orderOfSteps(1:backgroundCounter);
        descriptor = DAQPARS.MainApp.descriptorEditField.Value;
        if isempty(descriptor)
            fName = [DAQPARS.fileName,'.mat'];
        else
            fName = [DAQPARS.fileName,'_',descriptor,'.mat'];
        end
        inputData = squeeze(inputData(:,1:backgroundCounter,:)); %#ok<*NODEF>
        DAQPARS.orderOfSteps = DAQPARS.orderOfSteps(1:backgroundCounter);
        save([DAQPARS.saveDirectory,fName],...
            'outputData','inputData','Pars','-nocompression')

        if ishandle(progressFigure)
            close(progressDialog);
            close(progressFigure);
            if ~isempty(completedSweepsField)
                completedSweepsField.Value = 0;
                totalSweepsField.Value = 0;
            end
        end
        drawnow
        if strcmp(DAQPARS.MainApp.saveDropDown.Value,'save data')
            newexperiment('next trial')
            DAQPARS.preview.tempName = [];
        else
            descriptor = DAQPARS.MainApp.descriptorEditField.Value;
            if isempty(descriptor)
                fName = [DAQPARS.fileName,'.mat'];
            else
                fName = [DAQPARS.fileName,'_',descriptor,'.mat'];
            end
            DAQPARS.preview.fName1 = [DAQPARS.saveDirectory,fName];
            DAQPARS.preview.tempName = [DAQPARS.saveDirectory,'temp\',datestr(now,30),'_',fName];
            movefile(DAQPARS.preview.fName1, DAQPARS.preview.tempName)
        end
        set(DAQPARS.MainApp.startButton,'Text','start')
        app.Recording = false;
        warning('on')

end

stopBackground = [];


