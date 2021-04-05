function out = checkevokedmanually(analysisType,inputs,dt,MainApp,ap)
global acceptIdx

data = [];
for jj = 1:numel(inputs)
    
    startPt = max(round(MainApp.startEditField_2.Value/dt),1);
    stopPt = min(round(MainApp.stopEditField.Value/dt),length(inputs{jj}(:,:)));
    dataTemp = inputs{jj}(startPt:stopPt,:);
    data(1:size(dataTemp,1),end+1:end+size(dataTemp,2)) = dataTemp;
    
end

if strcmp(analysisType,'evoked')
    stimTime = ap.stimulusTime1;
else
    stimTime = [ap.stimulusTime1, ap.stimulusTime2];
end

app = manualcheck(data,dt,MainApp,stimTime,ap);
waitfor(app)
out = logical(acceptIdx);

