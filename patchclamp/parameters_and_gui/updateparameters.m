function [] = updateparameters(MainApp)
% function [] = updateparameters(MainApp)
%
% Updates the recording parameters contained in DAQPARS -- including things
% like sample rate and the mode of each channel (voltage clamp, current 
% clamp, field potential, off). This function is called whenever the user 
% makes a change in any of the parameters fields of the DAQ figure 
% (upper left panel).
%
% INPUT:    MainApp (handle to the main application).

global DAQPARS

eNo = MainApp.experimentNumberEditField.Value;
tNo = MainApp.trialNumberEditField.Value;
sampleRate = str2double(MainApp.sampleRateDropDown.Value);

nChannels = 8; % four with analog outputs, four with digital outputs

status = cell(8,1);
gain = ones(8,1);
holding = ones(8,1);
for ii = 1:nChannels
    
    s = ['statusDropDown_',num2str(ii)];
    g = ['gainDropDown_',num2str(ii)];
    h = ['holdingEditField_',num2str(ii)];
   
    status{ii} = MainApp.(s).Value;
    gain(ii) = str2double(MainApp.(g).Value);
    holding(ii) = MainApp.(h).Value;
    
end

DAQPARS.experimentNo = eNo;
DAQPARS.trialNo = tNo;
DAQPARS.sampleRate = sampleRate;
DAQPARS.channelStatus = status;
DAQPARS.channelGain = gain;
DAQPARS.channelHolding = holding;

