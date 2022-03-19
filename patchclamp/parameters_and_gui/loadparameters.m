function [] = loadparameters(fileName)
% function [] = loadparameters(fileName)
%
% load parameters file programmatically 
%
% INPUTS
% fileName:     name of file containing parameters

global DAQPARS %#ok<GVMIS> 

app = DAQPARS.MainApp;

try
    filePath = [DAQPARS.daqFolder,'\user_files\parameters\'];
    oldFolder = cd(filePath);
    pars = load(fileName);
    cd(oldFolder);
catch
    warndlg('Please check file name', 'File not found');
    error('File was not found');
end

try
    app.sampleRateDropDown.Value = num2str(pars.sampleRate);
    nChannels = numel(pars.gain);
    for ii = 1:nChannels
        s = ['statusDropDown_',num2str(ii)];
        g = ['gainDropDown_',num2str(ii)];
        h = ['holdingEditField_',num2str(ii)];
        if ii<5 % only the first four channels have an enable switch
            eStr = ['enableSwitch_',num2str(ii)];
            if strcmp(app.(eStr).Value,'disable') && ~strcmp(status{ii},'off') %#ok<*USENS>
                app.(eStr).Value = 'enable';
                app.(s).Enable = true;
            end
        end
        app.(s).Value = pars.status{ii};
        app.(g).Value = num2str(pars.gain(ii));
        app.(h).Value = pars.holding(ii);
    end
    channelStatusOld = DAQPARS.channelStatus;
    DAQPARS.sampleRate = pars.sampleRate;
    DAQPARS.channelStatus = pars.status;
    DAQPARS.channelGain = pars.gain;
    DAQPARS.channelHolding = pars.holding;
    writemulticlamp(app)
    updateBoard = updatenidaqboard(channelStatusOld,DAQPARS.channelStatus);
    if updateBoard
        DAQPARS.daqObj = nidaqboard;
    end
catch
    warndlg('Not a valid parameters file','File not valid');
    error('Call to loadparameters failed.')
end



