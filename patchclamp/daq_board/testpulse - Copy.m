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
% 
% Last modified: NSD, 03/06/22

global DAQPARS testObj %#ok<GVMIS> 

warning('off')

daqreset

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
    delete(testObj)
    DAQPARS.daqObj = nidaqboard;
    app.UIInputAxes2.YLabel.String = 'mV or pA';
    app.UIInputAxes2.XLabel.String = 'time (msec)';
    return
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
testChannelsType = zeros(numel(testChannels),1);
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
            case 'current clamp'
                outputGains(ii) = ampInfoChannel.outputScalingCurrentClamp;
                inputGains(ii) = ...
                    channelGain/ampInfoChannel.inputScalingCurrentClamp;
                testChannelsType(ii) = 1;
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
testObj = daq("ni");
testObj.Rate = sampleRate;
aiChannels = DAQPARS.daqBoardChannels(1,channelIdx);
addinput(testObj,DAQPARS.daqBoardInfo.ID,aiChannels,"Voltage");
aoChannels = DAQPARS.daqBoardChannels(2,channelIdx);
addoutput(testObj,DAQPARS.daqBoardInfo.ID,aoChannels,"Voltage");
dataTemp = readwrite(testObj,outputs,"OutputFormat","Matrix"); % used to set y-axis scale
dataTemp = dataTemp ./ repmat(inputGains(channelIdx),length(dataTemp),1);
testObj.ScansAvailableFcnCount = N;
testChannelsType = testChannelsType(channelIdx);
testObj.ScansAvailableFcn = @(src,evt) plottestdata(src,app,channelIdx,testChannelsType,pulseStart,pulseEnd,amplitude,inputGains);

% figure out where to plot the recordings
app.UIPlottingChannels.Data = false(2,8);
app.UIPlottingChannels.Data(1,channelIdx) = true;
[xPlot,~] = find(app.UIPlottingChannels.Data);

% get the graphs ready
cla(app.UIInputAxes1); cla(app.UIInputAxes2);
load('plottingColors.mat','colors')  % this is in the parameters_and_gui folder
rTime = minScansAvailable*dt/1000; % seconds between resistance measurements
yPts = 100; % number of resistance measurements to plot at one time
for jj = 1:numel(channelIdx)
    ax = ['UIInputAxes',num2str(xPlot(jj))];
    ax = app.(ax);
    color = colors(channelIdx(jj),:);
    plotHandle(jj) = line(ax,(1:N)*dt,dataTemp(1:N,jj),'color',color); %#ok<AGROW>
    ax2 = app.UIInputAxes2;
    rHandle(jj) = plot(ax2,(1:yPts)*rTime,NaN(yPts,1),'.','color',color); %#ok<AGROW> 
    rIdx = 1;
end
xlim(app.UIInputAxes1,[0 N*dt])
yLimit = min(5000, 1.25*max(abs(dataTemp(:))));
ylim(app.UIInputAxes1,[-yLimit yLimit])
xlim(app.UIInputAxes2,[0 round(rTime*yPts)])
ylim('auto')
app.UIInputAxes2.YLabel.String = 'M\Omega';
app.UIInputAxes2.XLabel.String = 'time (s)';
app.UIInputAxes2.YRuler.Exponent = 0;
ytickformat(app.UIInputAxes2,'%0.2f')

% preload output data and start DAQ object
preload(testObj,outputs)
start(testObj,"RepeatOutput")

% function that reads the data and plots it
    function [] = plottestdata(obj,app,idx,testChannelsType,pulseStart,pulseEnd,amplitude,inputGains)
        data = read(obj,obj.ScansAvailableFcnCount,"OutputFormat","Matrix");
        for kk = 1:size(data,2)
            plotHandle(kk).YData = data(:,kk)/inputGains(idx(kk));
            dataTemp1 = plotHandle(kk).YData;
            baseline = mean(dataTemp1(25:50));
            deflection = mean(dataTemp1(pulseEnd-35:pulseEnd-5)) - baseline;
            if testChannelsType(kk)==0  % voltage clamp
                R = abs(1000*amplitude/deflection); % MOhms
            else % current clamp
                R = abs(1000*deflection/amplitude);
            end
            rHandle(kk).YData(rIdx) = R;   
            if app.checkPropertiesButton.Value
                if channelIdx(1) == idx(kk)
                    app.inputresistanceEditField.Value = R;
                    app.holdingcurrentEditField.Value = baseline;
                    if testChannelsType(kk)==0 % voltage clamp
                        maxDeflection = max(abs(dataTemp1(pulseStart-5:pulseStart+5)))-baseline;
                        Rs = abs(1000*amplitude/maxDeflection);
                        app.seriesresistanceEditField.Value = Rs;
                    end
                end
            end

        end
        rIdx = max(rem(rIdx+1,yPts),1);
        if rIdx==1
            rValues = zeros(yPts*size(data,2),1);
            for kk = 1:size(data,2)
                rValues((kk-1)*yPts+1:kk*yPts) = rHandle(kk).YData;
                rValues(kk*yPts) = rValues(kk*yPts-1);
            end
            if any(isnan(rValues)), return, end
        end
    end
end