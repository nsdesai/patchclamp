function [varargout] = patchclamp(varargin)
% function [varargout] = patchclamp(varargin)
%
% This is the main program for data acquisition (DAQ). When called with no 
% arguments, it initializes the DAQ system and opens the GUI, using default
% parameters. When called with an argument (usually through the GUI), it 
% routes commands to the appropriate function(s).
%
% The basic parameters the program needs (e.g., sample rate, device ID of
% IO board, current time, recording mode) are contained in a structure
% array called DAQPARS. It is global and used by most of the DAQ functions.
%
% Written by Niraj S. Desai (NSD)
% Last modified: June 7, 2020

global DAQPARS

if (nargin==0)                          % initialize
    
    % All the DAQ files should be in the "patchclamp" folder inside the
    % Matlab work folder 
    % (e.g., C:\Users\MyName\Documents\MATLAB\patchclamp).
    workFolder = userpath;
    
    DAQPARS.daqFolder = [workFolder(1:end),'\patchclamp'];
    assert(isfolder(DAQPARS.daqFolder),...
        'The folder containing the DAQ files could not be found.')
    
    
    addpath(genpath(DAQPARS.daqFolder)) % add everything to the search path
    
    
    daqreset                            % delete any active daq objects
    
    
    if ~isfield(DAQPARS,'MainApp')
       opendaqfigure                       % open GUI with default parameters
    end
 
    
    [daqBoardOkay, amplifierOkay] = ... % check that IO board is working
        checkhardware;                  % and look for a patch clamp
                                        % amplifier
    
    assert(daqBoardOkay && amplifierOkay, ...
        'Check that the DAQ board and the amplifier are okay.')
    
    readmulticlamp(DAQPARS.MainApp)

    createsavedirectory                 % create folder in which to save
                                        % data
    
    makefilename('initial')             % create file name for initial data
    
    updateparameters(DAQPARS.MainApp)

    updateoutputs(DAQPARS.MainApp)

    channelOn = ~strcmp(DAQPARS.channelStatus,'off');
    DAQPARS.inputChannels = find(channelOn);
    if isempty(DAQPARS.inputChannels)
        DAQPARS.MainApp.enableSwitch_1.Value = true;
        DAQPARS.MainApp.statusDropDown_1.Value = 'field potential';
        updateparameters(DAQPARS.MainApp)
        DAQPARS.inputChannels = 1;
    end
    DAQPARS.daqObj = nidaqboard;

else                                    % feval switchyard
    
    if (nargout)
        [varargout{1:nargout}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
    
end

% Permission is hereby granted, free of charge, to any person obtaining
% a copy of this software and associated documentation files
% (the "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:
% 
% The above copyright notice and this permission notice shall be included 
% in all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
% CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
% OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR 
% THE USE OR OTHER DEALINGS IN THE SOFTWARE.
