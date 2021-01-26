function varargout = detectminis(varargin)
% Last modified 01/27/17 -- Niraj S. Desai

if (nargin==0)  % initialize
    openfig('detectminis.fig','reuse');
    updatepath(1);
    cleargraph
    loadparameters(1);
elseif ischar(varargin{1}) % Invoke named subfunction or callback
    try
        if (nargout)
            [varargout{1:nargout}] = feval(varargin{:});
        else
            feval(varargin{:});
        end
    catch ME
        disp(ME);
    end
end


% *************************************************************************
function [] = loadparameters(par)
global DM_params

if par == 1 % initial

    DM_params.date = datestr(now,1);
    DM_params.cell = '01';
    DM_params.trial = '001';
    DM_params.rep = '001';
    DM_params.range = '10000:20000';
    DM_params.amplitude = '10';
    DM_params.risetime = '2';
    DM_params.area = '10';
    DM_params.polarity = 'negative'; % negative for inward currents, 
                                     % positive for outward currents
 
    set(findobj('Tag','DM_date'),'String',DM_params.date)
    set(findobj('Tag','DM_cell'),'String',DM_params.cell)
    set(findobj('Tag','DM_trial'),'String',DM_params.trial)
    set(findobj('Tag','DM_rep'),'String',DM_params.rep)
    set(findobj('Tag','DM_range'),'String',DM_params.range)
    set(findobj('Tag','DM_amplitude'),'String',DM_params.amplitude)
    set(findobj('Tag','DM_risetime'),'String',DM_params.risetime)
    set(findobj('Tag','DM_area'),'String',DM_params.area)
    if strcmp(DM_params.polarity,'negative')
        set(findobj('Tag','DM_polarity'),'Value',1)
    else
        set(findobj('Tag','DM_polarity'),'Value',2)
    end
    
elseif par == 2 % update
    
   DM_params.date = get(findobj('Tag','DM_date'),'String');
   DM_params.cell = get(findobj('Tag','DM_cell'),'String');
   DM_params.trial = get(findobj('Tag','DM_trial'),'String');
   DM_params.rep = get(findobj('Tag','DM_rep'),'String');
   DM_params.range = get(findobj('Tag','DM_range'),'String');
   DM_params.amplitude = get(findobj('Tag','DM_amplitude'),'String');
   DM_params.risetime = get(findobj('Tag','DM_risetime'),'String');
   DM_params.area = get(findobj('Tag','DM_area'),'String');
   polarityOptions = get(findobj('Tag','DM_polarity'),'String');
   DM_params.polarity = ...
       polarityOptions{get(findobj('Tag','DM_polarity'),'Value')};

end

clns = find(DM_params.range==':');
boo = str2double(DM_params.range(1:clns(1)-1));
if boo<=0
    DM_params.range = ['1:',DM_params.range(clns(1)+1:end)];
end


% *************************************************************************
function [] = updatepath(par)
global DM_loadPath DM_savePath DM_fileName DM_pathName;

if par == 1 % Defaults at start
    DM_loadPath = [pwd,'\'];
    DM_savePath = [pwd,'\'];
    set(findobj('Tag','DM_loadfile'),'String','Choose')
    set(findobj('Tag','DM_savedirectory'),'String',DM_savePath)
elseif par == 2 % Load file
    cd1 = pwd;
    cd(DM_loadPath);
    [DM_fileName,DM_pathName] = uigetfile({'*.mat;*.ibw'},'Choose File');
    if DM_fileName
        DM_loadPath = DM_pathName;
        set(findobj('Tag','DM_loadfile'),'String',DM_fileName)
    end
    cd(cd1)
    loadfile
elseif par == 3 % Change save directory
    cd1 = pwd;
    cd(DM_savePath);
    c1 = uigetdir('','Choose a directory');
    if c1
        DM_savePath = [c1,'\'];
        set(findobj('Tag','DM_savedirectory'),'String',DM_savePath)
    end
    cd(cd1)
end
   

% *************************************************************************
function [] = cleargraph

axes(findobj('Tag','DM_wholewave')); cla;
axes(findobj('Tag','DM_clippedwaves')); cla;


% *************************************************************************
function [] = loadfile
global DM_fileName DM_pathName dt DM_wave

if strcmp(DM_fileName(end-2:end),'ibw') % Igor binary wave
    foo = IBWread([DM_pathName, DM_fileName]);
    inputData = foo.y;  
    dt = foo.dx;  % <--- time step in milliseconds
    DM_date = datestr(foo.creationDate,1);
else  % Matlab MAT file
    load([DM_pathName, DM_fileName])
    DM_date = datestr(Pars.time,1);
    dt = 1000/Pars.sampleRate;
end

try
    set(findobj('Tag','DM_date'),'String',DM_date)
    set(findobj('Tag','DM_cell'),'String',DM_fileName(11:13))
    set(findobj('Tag','DM_trial'),'String',DM_fileName(19:21))
catch
    % naming convention is different
end

DM_wave = inputData;
Fs = 1000/dt;
if get(findobj('Tag','DM_60Hz'),'Value')
    try     % 60 cycle notch filter
        wo = 60/(Fs/2);
        bw = wo/35;
        [b,a] = iirnotch(wo,bw);
        DM_wave = filtfilt(b,a,DM_wave);
    catch
        try
            Fs = round(Fs/1000);
            filterStr = ['Filter_parameters_60Hz_',num2str(Fs),'kHz.mat'];
            load(filterStr)
            DM_wave = filtfilt(b,a,DM_wave);
        catch
            % iirnotch not available
        end
    end
end

loadparameters(2);


% *************************************************************************
function [] = acceptminis  %#ok<*DEFNU>
global DM_params DM_savePath
global analyzedData  %#ok<NUSED>

saveName = ['minis_',DM_params.date(8:11),'_',DM_params.date(4:6),...
    '_',DM_params.date(1:2),'_c',...
    DM_params.cell,'t',DM_params.trial,'r',DM_params.rep,'.mat'];
cd1 = pwd;
cd(DM_savePath);

dirName = ['minis',datestr(DM_params.date,26),'/c',DM_params.cell,'/'];
if ~isdir(dirName)
    mkdir(dirName)
end

cd(dirName);
save(saveName, 'analyzedData','DM_params');
cd(cd1);


% *************************************************************************
function [] = analyze 
global DM_wave DM_params dt
global rangeNumber analyzedData

% the default of the analyze function is that the synaptic currents to be
% detected are inward (e.g., EPSCs recorded at resting potential). if the
% currents are instead outward, we flip the sign of the data traces, do the
% analysis, and then flip them back
if strcmp(DM_params.polarity,'positive')
    DM_wave = -DM_wave;
end

bStart = round(5/dt);   % Minimum buffer time before baseline subtract
bDuration = round(4.5/dt);    % Duration of baseline 

tPt = -str2double(DM_params.amplitude); % Threshold cutoff in pA

minSepBefore = round(10/dt);  % Minimum time to previous event
minSepAfter = round(10/dt); % Minimum time to next event
stdCutoff = 3;  % Standard deviation cutoff (of order 1 pA) -- Should be
                  % a bit more than 1/2 the std. dev. of the unfiltered
                  % wave in the absence of events (find a quiet stretch)

rTimeLimit = str2double(DM_params.risetime);  % Risetime cutoff, in msec

minArea = str2double(DM_params.area);  % Area cutoff in fC

repNumber = str2double(DM_params.rep);
clns = find(DM_params.range==':');
cmms = find(DM_params.range==',');

r{1} = str2double(DM_params.range(1:clns(1)-1))/...
    dt:str2double(DM_params.range(clns(1)+1:end))/dt;
if ~isempty(cmms)
    r{2} = str2double(DM_params.range(cmms(1)+1:clns(2)-1))/...
        dt:str2double(DM_params.range(clns(2)+1:end))/dt;
end
if length(cmms)>1
    r{3} = str2double(DM_params.range(cmms(2)+1:clns(3)-1))/...
        dt:str2double(DM_params.range(clns(3)+1:end))/dt;
end
if length(cmms)>2
    r{4} = str2double(DM_params.range(cmms(3)+1:clns(4)-1))/...
        dt:str2double(DM_params.range(clns(4)+1:end))/dt;
end
if length(cmms)>3
    r{5} = str2double(DM_params.range(cmms(4)+1:clns(5)-1))/...
        dt:str2double(DM_params.range(clns(5)+1:end))/dt;
end
rangeNumber = [];
for iCount = 1:size(r,2)
    rangeNumber = [rangeNumber r{iCount}]; %#ok<AGROW>
end


rangeNumber(rangeNumber>length(DM_wave(:,repNumber)))=[]; 
oWave = DM_wave(rangeNumber,repNumber);

%   fWave is the filtered wave. Averaging 2 msec before each point.  
% fWave = smooth(oWave,19);
fWave = sgolayfilt(oWave,3,19);

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
    tPts2 = [];
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
%         diffVar(jCount) = abs(vVar(jCount) - hVar(jCount));
        totalVar(jCount) = vVar(jCount)+hVar(jCount);
    end;
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

if isempty(rTime)
    disp('No EPSCs found -- adjust detection criteria')
    return
end

% Clip out events and zero the baseline
clipped = zeros(length(startPt),round(60/dt)+1);
for iCount = 1:length(startPt)
    clipped(iCount,:) = oWave(startPt(iCount)-10/dt:startPt(iCount)+50/dt);
    clipped(iCount,:) = clipped(iCount,:) - mean(clipped(iCount,1:10/dt));
end

% Implement area cutoff
areaEvent = zeros(length(tPts4),1);
for iCount = 1:length(tPts4)
    areaEvent(iCount)=abs(dt*trapz(clipped(iCount,:)));
end;
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
if strcmp(DM_params.polarity,'positive')
    DM_wave = -DM_wave;
    oWave = -oWave;
    fWave = -fWave;
    clipped = -clipped;
end


axes(findobj('Tag','DM_wholewave'));cla;
plot((1:length(oWave))*dt, oWave); hold on;
plot(startPt*dt,fWave(startPt),'ro');
plot(tPts4*dt,fWave(tPts4),'go');
% plot((1-secondPeak).*tPts4*dt,-10,'ms');
xlim([0 length(oWave)*dt]);
ylim('auto');

aveClipped = mean(clipped);
axes(findobj('Tag','DM_clippedwaves'));cla;
plot((1:size(clipped,2))*dt,clipped,'b',...
    (1:size(clipped,2))*dt,aveClipped,'r');
xlim([0 size(clipped,2)*dt]);
ylim('auto');

timelength = length(oWave)*dt/1000;

analyzedData.clipped = clipped';
analyzedData.amp = ampEvent;
analyzedData.rise = rTime;
analyzedData.area = areaEvent;
analyzedData.second = secondPeak;
analyzedData.timelength = timelength;

mininumber = length(ampEvent);
minifrequency = mininumber/(length(oWave)*dt/1000);
miniamplitude = mean(ampEvent);
minirisetime = mean(rTime);
miniarea = mean(areaEvent);
set(findobj('Tag','DM_mininumber'),'String',num2str(mininumber));
set(findobj('Tag','DM_minifrequency'),'String',num2str(minifrequency,2));
set(findobj('Tag','DM_miniamplitude'),'String',num2str(miniamplitude,3));
set(findobj('Tag','DM_minirisetime'),'String',num2str(minirisetime,2));
set(findobj('Tag','DM_miniarea'),'String',num2str(miniarea,'%5.2f'));




