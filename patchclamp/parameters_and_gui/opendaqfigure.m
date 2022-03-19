function [] = opendaqfigure
% function [] = opendaqfigure
%
% The function is called when the main DAQ program is opened. It applies
% default parameters and output values to the DAQ GUI.

global DAQPARS

DAQPARS.MainApp = LCSMS_patch_clamp;

% initial parameters
DAQPARS.time = now;
DAQPARS.nChannels = 8;  % there are 8 analog channels
DAQPARS.experimentNo = 1;
DAQPARS.trialNo = 1;
DAQPARS.sampleRate = 20000;
DAQPARS.posthoc = false;    % do posthoc analysis on acquired data (or not)

