global DAQPARS
app = DAQPARS.MainApp;

loadparametes('myparametersA')
loadoutputs('myoutputsA')
pushStartButton(app)


buttonName = questdlg('Keep recording?','Experiment ongoing','Yes', 'No', 'Yes');
switch buttonName
    case 'Yes'
       % keep going
    case 'No'
       return
end

loadparametes('myparametersB')
loadoutputs('myoutputsB')
pushStartButton(app)


buttonName = questdlg('Keep recording?','Experiment ongoing','Yes', 'No', 'Yes');
switch buttonName
    case 'Yes'
       % keep going
    case 'No'
       return
end

loadparametes('myparametersC')
loadoutputs('myoutputsC')
pushStartButton(app)
