function [] = loadoutputs(fileName)
% function [] = loadoutputs(fileName)
%
% load outputs file programmatically 
%
% INPUTS
% fileName:     name of file containing output values

global DAQPARS

app = DAQPARS.MainApp;

try
    filePath = [DAQPARS.daqFolder,'\user_files\outputs\'];
    oldFolder = cd(filePath);
    load(fileName);     %#ok<LOAD> % the values are saved in a struct called "outputs"
    cd(oldFolder)
catch
    warndlg('Please check file name', 'File not found');
    error('File was not found');
end

try
    app.periodEditField.Value = outputs.period;
    app.repetitionsEditField.Value = outputs.repetitions;
    app.durationEditField.Value = outputs.duration;
    app.shuffleCheckBox.Value = outputs.shuffle;
    app.UIOutputChannels.Data = outputs.channels;
    app.UIOutputData.Data = outputs.data;
    updateoutputs(app);
catch
    warndlg('Not a valid outputs file','File not valid');
    error('Call to loadoutputs failed.')
end
