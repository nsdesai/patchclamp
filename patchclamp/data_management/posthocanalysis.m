function [] = posthocanalysis(input1,recordingMode)

global DAQPARS analysisCounter 
persistent analysisData analysisTimes zeroTime

app = DAQPARS.MainApp;

if isempty(analysisCounter)
    analysisCounter = 1;
    % all 8 input channels, up to 1000 values, and 3 types (R_N,V_m,R_s,other)
    analysisData = zeros(8,1000,4); 
    zeroTime = clock;
    analysisTimes = [];
else
    analysisCounter = analysisCounter + 1;
end

dt = 1000/DAQPARS.sampleRate;

if app.checkButton.Value
    
    startTime = round(app.beginningStabilityEditField.Value/dt);
    stopTime = round(app.endStabilityEditField.Value/dt);
    first = DAQPARS.stability.first;
    second = DAQPARS.stability.second;
    if stopTime < length(input1)
        for ii = 1:4
            if (app.UIStability.Data(ii)==0) || (recordingMode(ii)==0) || (recordingMode(ii)>2)
                continue
            end
            input2 = input1(startTime:stopTime,DAQPARS.inputChannels==ii);
            analysisData(ii,analysisCounter,2) = ...
                mean(input2(first-round(10/dt):first)); % holding current or resting potential
            if recordingMode(ii)==1 % voltage clamp
                baseline = abs(mean(input2(1:round(5/dt))));
                deflectionI = abs(mean(input2(second-round(5/dt):second))) - baseline;
                deflectionV = 1000*DAQPARS.stability.deflectionOutput(ii);
                peakI = max(abs(input2))-baseline;
                analysisData(ii,analysisCounter,3) = deflectionV/peakI;
            elseif recordingMode(ii)==2 % current clamp
                baseline = abs(mean(input2(1:round(5/dt))));
                deflectionV = abs(mean(input2(second-round(5/dt):second)))-baseline;
                deflectionI = 0.001*DAQPARS.stability.deflectionOutput(ii);
            end
            analysisData(ii,analysisCounter,1) = ...
                deflectionV/deflectionI - analysisData(ii,analysisCounter,3); % R_N    
        end
    end
    
end


switch app.otheranalysesDropDown.Value
    
    case 'none'
        
        % do nothing
        
    case 'firing rate'
        
    case 'PSC amplitudes'
        
    case 'PSP slopes'
        
    otherwise
        
        % modify so that it looks for saved analysis files
end


analysisTimes(analysisCounter) = etime(clock,zeroTime); % minutes since start of analysisload('plottingColors.mat','colors')  % this is in the parameters_and_gui folder
cla(app.UIAxesInputResistance);
cla(app.UIAxesRestingPotential);
cla(app.UIAxesSeriesResistance);
load('plottingColors.mat','colors')  % this is in the parameters_and_gui folder
for jj = 1:4
    if nnz(analysisData(jj,:,1))>0
        plot(app.UIAxesInputResistance,analysisTimes,...
            analysisData(jj,1:length(analysisTimes),1),...
            'color',colors(jj,:),'marker','.','linestyle','none')
        plot(app.UIAxesRestingPotential,analysisTimes,...
            analysisData(jj,1:length(analysisTimes),2),...
            'color',colors(jj,:),'marker','.','linestyle','none')
        plot(app.UIAxesSeriesResistance,analysisTimes,...
            analysisData(jj,1:length(analysisTimes),3),...
            'color',colors(jj,:),'marker','.','linestyle','none')
    end
end
    
    

