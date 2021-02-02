function [analyzedData,totalDuration,eventSamplePoints] = detectcurrents(data,ap,dt)

analyzedData.clipped = [];
analyzedData.amp = [];
analyzedData.rise = [];
analyzedData.area = [];
analyzedData.second = [];
analyzedData.startPt = [];
analyzedData.peakPt = [];
totalDuration = [];
eventSamplePoints = [];
if isempty(data), return, end

if ap.sixtyHz
    try     % 60 Hz notch filter
        Fs = round(1/dt); % kHz
        filterStr = ['Filter_parameters_60Hz_',num2str(Fs),'kHz.mat'];
        load(filterStr) %#ok<LOAD>
        data = filtfilt(b,a,data);
    catch
        % maybe the filters are ot present
    end
end

if ap.synapticDirection==1
    data = -data;
end

bStart = round(5/dt);   % Minimum buffer time before baseline subtract
bDuration = round(4.5/dt);    % Duration of baseline 

tPt = -ap.amplitude; % Threshold cutoff in pA
minSepBefore = round(10/dt);  % Minimum time to previous event
minSepAfter = round(10/dt); % Minimum time to next event
stdCutoff = 3;  % Standard deviation cutoff (of order 1 pA) -- Should be
                  % a bit more than 1/2 the std. dev. of the unfiltered
                  % wave in the absence of events (find a quiet stretch)
rTimeLimit = ap.riseTime;  % Risetime cutoff, in msec
minArea = ap.area;  % Area cutoff in fC


%   fWave is the filtered wave. Averaging 2 msec before each point.  
fWave = sgolayfilt(data,3,round(2/dt)-1);


%   Subtracting off baseline: bWave is the average of the
%   stretch bStart-(bStart+bDuration) msec before the point
%   in question. dWave is the baseline-subtracted wave.
bWave = filter([zeros(1,bStart) ones(1,bDuration)],bDuration,fWave);
dWave = fWave - bWave;

foundPSCs=true; tPts2=[]; tPts3=[]; tPts4=[];

%   The threshold is tPt. The last 50 msec of each wave are
%   not used, neither is the first 20 msec.
tPts1 = find(dWave<tPt);
tPts1(tPts1>(length(dWave)-50/dt))=[];
tPts1(tPts1<20/dt)=[];
if isempty(tPts1), foundPSCs = false; end

%   tPts3 is at the front edge of the peak in fWave, which is assumed
%   less than 3 msec wide.
if foundPSCs
    for iCount = 2:length(tPts1)-1
        if dWave(tPts1(iCount)) < dWave(tPts1(iCount-1))...
                && dWave(tPts1(iCount)) < dWave(tPts1(iCount+1))
            tPts2(end+1) = tPts1(iCount); %#ok<AGROW>
        end
    end
    dtPts = [1000 diff(tPts2)];
    tPts3 = tPts2;
    tPts3(dtPts<3/dt) = [];   % This is where the 3 msec wide
                                    % assumption comes in.
end
if isempty(tPts3), foundPSCs = false; end

%   tPts4 is tPts3 after the removal of peaks within minSepBefore msec of
%   another peak. Also, tPts4 finds the true peak.
if foundPSCs
    dtPts1 = [1000 diff(tPts3)];
    tPts4 = tPts3;
    tPts4(dtPts1<minSepBefore)=[];
    for iCount = 1:length(tPts4)
        [~,i] = min(fWave(tPts4(iCount):(tPts4(iCount)+1/dt)));
        tPts4(iCount)=tPts4(iCount)+i(1)-1;
    end
end
if isempty(tPts4), foundPSCs=false; end

if foundPSCs==false
    disp('No EPSCs found -- adjust detection criteria');
    return
end

%   Marks peaks which have another peak following it by less than
%   minSepAfter msec. Will not include in decay measurements.
secondPeak = tPts4;
secondPeak(:)=1;
dtPts2 = [diff(tPts4) 1000];
secondPeak(dtPts2<minSepAfter)=0;

%   Use std deviation of baseline immediately before (3-9 msec) event
%   to decide if it's stable enough.
stdWave = zeros(1,length(tPts4));
for iCount = 1:length(tPts4)
    t4 = tPts4(iCount);
    stdWave(iCount) = std(fWave(t4-9/dt:t4-3/dt));
end
tPts4(stdWave>stdCutoff)=[];
secondPeak(stdWave>stdCutoff)=[];

%   Find the start of the event (pivot point), up to 0.1-5.0 msec away
startPt = zeros(1,length(tPts4));
for iCount = 1:length(tPts4)
    for jCount = (5/dt):-1:1
        horizontal = fWave((tPts4(iCount)-5/dt):(tPts4(iCount)-jCount));
        hVar(jCount) = var(horizontal)*(length(horizontal)+1);

        vertical = fWave(tPts4(iCount)-jCount:tPts4(iCount));
        vSlope = (vertical(end)-vertical(1))/jCount;
        vIntercept = vertical(1)-vSlope;
        vFit = vertical;
        vFit(1:end) = (1:length(vFit))*vSlope + vIntercept;
        vVar(jCount) = sum((vertical-vFit).^2);
        totalVar(jCount) = vVar(jCount)+hVar(jCount);
    end
    [~,i] = min(totalVar);
    startPt(iCount) = tPts4(iCount)-i(1);
end

rTime = 0.6*(tPts4 - startPt - 0.4)*dt; % The 0.6 factor is so that the
                                           % rise time will be 20-80%. The
                                           % 0.4 is because startPt seems
                                           % be 0.4 msec earlier than one
                                           % would place the corner point
                                           % visually (empirically
                                           % determined).

% Implement rise time cutoff
tPts4(rTime>rTimeLimit)=[];
startPt(rTime>rTimeLimit)=[];
secondPeak(rTime>rTimeLimit)=[];
rTime(rTime>rTimeLimit)=[];

% Clip out events and zero the baseline
clipped = zeros(length(startPt),round(60/dt)+1);
for iCount = 1:length(startPt)
    clipped(iCount,:) = data(startPt(iCount)-10/dt:startPt(iCount)+50/dt);
    clipped(iCount,:) = clipped(iCount,:) - mean(clipped(iCount,1:10/dt));
end

% Implement area cutoff
areaEvent = zeros(length(tPts4),1);
for iCount = 1:length(tPts4)
    areaEvent(iCount)=abs(dt*trapz(clipped(iCount,:)));
end
tPts4(areaEvent<minArea)=[];
startPt(areaEvent<minArea)=[];
secondPeak(areaEvent<minArea)=[];
rTime(areaEvent<minArea)=[];
clipped(areaEvent<minArea,:)=[];
areaEvent(areaEvent<minArea)=[];

% Calculate amplitude of each event
ampEvent = zeros(length(tPts4),1);
for iCount = 1:length(tPts4)
    meanClipped = sgolayfilt(clipped(iCount,:),3,19);
    ampEvent(iCount)=-min(meanClipped(round(10.2/dt):round(15/dt)));
end
    
% if we flipped the sign of the data traces -- because we wanted to
% detected outward currents rather than inward currents -- we flip them and
% the resulting analyzed traces back before plotting and saving
if ap.synapticDirection==1
    data = -data;
    clipped = -clipped;
end

totalDuration = length(data)*dt/1000;
eventSamplePoints = size(clipped,2);

analyzedData.clipped = clipped;
analyzedData.amp = ampEvent(:);
analyzedData.rise = rTime(:);
analyzedData.area = areaEvent(:);
analyzedData.second = secondPeak(:);
analyzedData.startPt = startPt(:);
analyzedData.peakPt = tPts4(:);




