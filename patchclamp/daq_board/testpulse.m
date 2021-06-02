function [] = testpulse(app)
% [] = testpulse(app)
%
% testpulse(app) is called from the main acquisition GUI (app) when the
% "test" button is pushed. This starts a test pulse to be used for forming
% a gigaohm seal on one or more of the analog channels. The channels must
% be in current clamp or voltage clamp (you'll get an error if they are
% not). The amplitude and duration of the test pulse(s) are specified in
% the main GUI app. Given the board and Matlab, the maximum refresh rate is
% 20 Hz. The responses to the test pulses will be shown in the input axes
% of the main GUI.
%
% INPUTS
% app:      handle to the main acquisition app
%
% Niraj S. Desai (NSD), 09/01/2020.

global DAQPARS testObj

% if the test pulse is going and the user wants to stop it, they press the
% "test" button a second time. This sets app.TestPulse to false and
% triggers this daqreset and return
if ~app.TestPulse 
    testObj = daq("ni");
    testChannels = app.UITestPulse.Data;
    aoChannels = DAQPARS.daqBoardChannels(2,testChannels);
    addoutput(testObj,DAQPARS.daqBoardInfo.ID,aoChannels,"Voltage");
    outputs = zeros(1,numel(aoChannels));
    write(testObj,outputs)
    daqreset
    return
end

% clear the calculated resistance values in the GUI
for jj = 1:4
    fStr = ['channel',num2str(jj),'REditField'];
    app.(fStr).Value = 0;
end

% sample rate and amplifier information; we always use 10 kHz for this
sampleRate = 10000; % Hz
dt = 1000/sampleRate; % msec
ampInfo = DAQPARS.amplifierInfo(DAQPARS.amplifierIdx);

% get the amplitude and duration of the test pulse(s) from the GUI
amplitude = app.amplitudeTestEditField.Value;
duration = app.durationTestEditField.Value;
pulseBuffer = max(5,ceil(duration/2));
totalLength = pulseBuffer + duration + pulseBuffer;

% check that a test channel has been selected
testChannels = app.UITestPulse.Data;
if isempty(find(testChannels, 1))
    app.testButton.Text = 'test';
    warndlg('Select test channels first','Check parameters')
    return
end

% check that the selected channels are in voltage clamp
% get the gains for this condition
outputGains = ones(1,numel(testChannels));
inputGains = outputGains;
for ii = 1:numel(testChannels)
    if testChannels(ii)
        ampInfoChannel = ampInfo(ii);
        channelStatus = DAQPARS.channelStatus{ii};
        channelGain = DAQPARS.channelGain(ii);
        switch channelStatus
            case 'voltage clamp'
                outputGains(ii) = ampInfoChannel.outputScalingVoltageClamp;
                inputGains(ii) = ...
                    channelGain/ampInfoChannel.inputScalingVoltageClamp;
            otherwise
                warndlg('All test channels must be in voltage clamp','Check parameters')
                app.testButton.Text = 'test';
                return
        end
    end
end

% create the test pulses
channelIdx = find(testChannels);
outputs = zeros(round(totalLength/dt),numel(channelIdx));
pulseStart = round(pulseBuffer/dt);
pulseEnd = pulseStart + round(duration/dt);
for mm = 1:numel(channelIdx)
    outputs(pulseStart:pulseEnd,:) = amplitude / outputGains(channelIdx(mm));
end
minPreload = ceil(sampleRate/2); % minimum number of samples for preload function
minScansAvailable = max(ceil(sampleRate/10),length(outputs)); % maximum counts to trigger ScanAvailableFcn
if length(outputs)<minPreload
    replicates = ceil(minPreload/length(outputs));
    outputs = repmat(outputs,replicates,1);
end
N = minScansAvailable; % N may be shorter than outputs

% create DAQ object
daqreset
testObj = daq("ni");
testObj.Rate = sampleRate;
aiChannels = DAQPARS.daqBoardChannels(1,channelIdx);
addinput(testObj,DAQPARS.daqBoardInfo.ID,aiChannels,"Voltage");
aoChannels = DAQPARS.daqBoardChannels(2,channelIdx);
addoutput(testObj,DAQPARS.daqBoardInfo.ID,aoChannels,"Voltage");
dataTemp = readwrite(testObj,outputs,"OutputFormat","Matrix"); % used to set y-axis scale
dataTemp = dataTemp ./ repmat(inputGains(channelIdx),length(dataTemp),1);
testObj.ScansAvailableFcnCount = N;
testObj.ScansAvailableFcn = @(src,evt) plottestdata(src,app,channelIdx,pulseStart,amplitude,inputGains);

% figure out where to plot the recordings
app.UIPlottingChannels.Data = false(2,8);
if numel(channelIdx)== 1
    app.UIPlottingChannels.Data(1,channelIdx) = true;
elseif numel(channelIdx) == 2
    app.UIPlottingChannels.Data(1,channelIdx(1)) = true;
    app.UIPlottingChannels.Data(2,channelIdx(2)) = true;
elseif numel(channelIdx) == 3
    app.UIPlottingChannels.Data(1,channelIdx(1:2)) = true;
    app.UIPlottingChannels.Data(2,channelIdx(3)) = true;
else
    app.UIPlottingChannels.Data(1,channelIdx(1:2)) = true;
    app.UIPlottingChannels.Data(2,channelIdx(3:4)) = true;
end
[xPlot,~] = find(app.UIPlottingChannels.Data);

% get the graphs ready
cla(app.UIInputAxes1); cla(app.UIInputAxes2);
load('plottingColors.mat','colors')  % this is in the parameters_and_gui folder
for jj = 1:numel(channelIdx)
    ax = ['UIInputAxes',num2str(xPlot(jj))];
    ax = app.(ax);
    color = colors(channelIdx(jj),:);
    plotHandle(jj) = plot(ax,(1:N)*dt,dataTemp(1:N,jj),'color',color); %#ok<AGROW>
end
xlim(app.UIInputAxes1,[0 N*dt])
xlim(app.UIInputAxes2,[0 N*dt])
yLimit = min(5000, 1.25*max(abs(dataTemp(:))));
ylim(app.UIInputAxes1,[-yLimit yLimit])
ylim(app.UIInputAxes2,[-yLimit yLimit])

% preload output data and start DAQ object
preload(testObj,outputs)
start(testObj,"RepeatOutput")

% function that reads the data and plots it
    function [] = plottestdata(obj,app,idx,pulseStart,amplitude,inputGains)
        data = read(obj,obj.ScansAvailableFcnCount,"OutputFormat","Matrix");
        for kk = 1:size(data,2)
            plotHandle(kk).YData = data(:,kk)/inputGains(idx(kk));
            dataTemp = plotHandle(kk).YData;
            fStr = ['channel',num2str(idx(kk)),'REditField'];
            deflection = mean(dataTemp(pulseStart+25:pulseStart+50)) - mean(dataTemp(25:50));
            R = abs(1000*amplitude/deflection); % MOhms
            app.(fStr).Value = R;
        end
    end

end


