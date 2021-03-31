function out = checkevokedmanually(inputs,dt,MainApp)
global acceptIdx

data = [];
for jj = 1:numel(inputs)
    
    startPt = max(round(MainApp.startEditField_2.Value/dt),1);
    stopPt = min(round(MainApp.stopEditField.Value/dt),length(inputs{jj}(:,:)));
    dataTemp = inputs{jj}(startPt:stopPt,:);
    data(1:size(dataTemp,1),end+1:end+size(dataTemp,2)) = dataTemp;
    
end

app = manualcheck(data,dt,MainApp);
waitfor(app)
out = logical(acceptIdx);

