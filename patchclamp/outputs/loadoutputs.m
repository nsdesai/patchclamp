function [] = loadoutputs(fileName)
% function [] = loadoutputs(fileName)
%
% load outputs file programmatically 
%
% INPUTS
% fileName:     name of file containing output values

global DAQPARS

app = DAQPARS.MainApp;

if ~nargin || ~exist(fileName,'file')
    filePath = [DAQPARS.daqFolder,'\user_files\outputs\'];
    try
        load([filePath,fileName]); %#ok<*LOAD>
    catch
        warndlg('Please check file name', 'File not found');
        error('File was not found');
    end
else
    filePath = [DAQPARS.daqFolder,'\user_files\outputs\'];
    oldFolder = cd(filePath);
    load(fileName);     % the values are saved in a struct called "outputs"
    cd(oldFolder)
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
