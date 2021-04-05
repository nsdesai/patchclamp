global DAQPARS
app = DAQPARS.MainApp;

% loadparameters('myparametersA')
% pushWriteMulticlampButton(app)
loadoutputs('myoutputsA')
pushStartButton(app)


while app.Recording
    drawnow limitrate
end

% buttonName = questdlg('Keep recording?','Experiment ongoing','Yes', 'No', 'Yes');
% switch buttonName
%     case 'Yes'
%        % keep going
%     case 'No'
%        return
% end

% loadparameters('myparametersB')
% pushWriteMulticlampButton(app)
loadoutputs('myoutputsB')
pushStartButton(app)


while app.Recording
    drawnow limitrate
end

% buttonName = questdlg('Keep recording?','Experiment ongoing','Yes', 'No', 'Yes');
% switch buttonName
%     case 'Yes'
%        % keep going
%     case 'No'
%        return
% end

% loadparameters('myparametersC')
% pushWriteMulticlampButton(app)
loadoutputs('myoutputsC')
pushStartButton(app)
