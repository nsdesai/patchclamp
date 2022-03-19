function [daqBoardOkay, amplifierOkay, amplifierDetected] = checkhardware
% function [daqBoardOkay, amplifierOkay] = checkhardware
%
% OUTPUTS
% daqBoardOkay:         true or false   (IO board)
% amplifierOkay:        true or false   (patch clamp amplifier)    

global DAQPARS

% The standard hardware configurations for both the IO board and the
% amplifier are stored in a MAT file in the "parameters_and_gui" subfolder.
% It specifies, for example, the IO board's device ID and channels and the
% gain settings of the amplifier. If the file does not exist or does not
% conform to the detected hardware, the user is asked to update the 
% hardware configuration through the hardware GUI.
hardwareConfiguration = [DAQPARS.daqFolder,...
    '\parameters_and_gui\hardwareConfiguration.mat'];

try
    
    hConfig = load(hardwareConfiguration);
    
    [daqBoardOkay] = ...
        checkdaqboard(hConfig.daqBoardInfo);
    
    [amplifierOkay] = ...
        checkamplifier(hConfig.amplifierInfo,hConfig.amplifierIdx);
    
    % If there are any problems with the IO (DAQ) board or the
    % amplifier, we assert an error. This forces us to execute the
    % catch statement.
    assert(daqBoardOkay && amplifierOkay)

    
catch 
    
    disp('Choose new hardware configuration or check hardware.')
    
    % The user is asked to specify new configuration through hardware GUI.
    DAQPARS.MainApp.pushHardwareButton;
    
    while ~isempty(findobj('Tag','LCSMS_hardware'))
        drawnow % wait for user to finalize configuration
    end
    
    % Again check that all is okay
    hConfig = load(hardwareConfiguration);
    [daqBoardOkay] = ...
        checkdaqboard(hConfig.daqBoardInfo);
    [amplifierOkay] = ...
        checkamplifier(hConfig.amplifierInfo,hConfig.amplifierIdx);
    assert(daqBoardOkay && amplifierOkay, 'Hardware still not okay. Cancelling ...')

end

DAQPARS.daqBoardInfo = hConfig.daqBoardInfo;
DAQPARS.daqBoardIdx = hConfig.daqBoardIdx;
DAQPARS.daqBoardChannels = hConfig.daqBoardChannels;
DAQPARS.amplifierInfo = hConfig.amplifierInfo;
DAQPARS.amplifierIdx = hConfig.amplifierIdx;


