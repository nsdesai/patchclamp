function [] = newexperiment(~)
% function [] = newexperiment(~)
% 
% When called without an argument, the experiment number is incremented.
% When called with an argument, the experiment number is unchanged but the
% trial number is incremented.

global DAQPARS analysisCounter

if nargin     % 'new trial'
    DAQPARS.trialNo = DAQPARS.trialNo + 1;
else          % 'new experiment'
    DAQPARS.experimentNo = DAQPARS.experimentNo + 1;
    DAQPARS.trialNo = 1;
    analysisCounter = [];
    cla(DAQPARS.MainApp.UIAxesInputResistance)
    cla(DAQPARS.MainApp.UIAxesRestingPotential)
    cla(DAQPARS.MainApp.UIAxesSeriesResistance)
end

DAQPARS.MainApp.experimentNumberEditField.Value = num2str(DAQPARS.experimentNo);
DAQPARS.MainApp.trialNumberEditField.Value = num2str(DAQPARS.trialNo);


makefilename