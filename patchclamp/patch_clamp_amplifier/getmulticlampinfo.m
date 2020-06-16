function amplifierInfo = getmulticlampinfo(hWait)
% function amplifierInfo = getmulticlampinfo(hWait)
%
% This function gets scaling information for the channels of any open
% Multiclamp Commander. It is called by the hardware GUI, which in turn is
% called when the user presses the "hardware" button of the main patch
% clamp GUI or if the hardware configuration file cannot be found.
% 
% It depends upon two C++ projects. The first (MulticlampTelegraph)
% is part of Janelia's Wavesurfer electrophysiology project (currently
% being developed by Adam Taylor and Ben Arthur, wavesurfer.janelia.org).
% The code can be found in patchclamp/third_party_utilities/multiclamptelegraph.
% I made only one change: in the case condition (case = 1) of line 449, 
% the original code always returned V/nA; now we sometimes get V/uA (this
% is relevant only for the Multiclamp 700A when the feedback resistor is 50
% MOhms). To compile it into a usable MEX function, run this command:
% mex -I"C:\Program Files (x86)\Molecular Devices\MultiClamp 700B Commander\3rd Party Support\Telegraph_SDK" MultiClampTelegraph.cpp
% Note that we specify the location of the SDK provided by Molecular
% devices.
%
% The second (MulticlampControl) is a Microsoft Visual Studio 2015 project
% written for the automated patch clamp system. It uses a different part of
% the Molecular Devices SDK: AxMultiClampMsg. One should not need to
% rebuild the project, but if you wish to do so, make sure it is 32 bit
% (i.e., choose 'x86' rather than 'x64' at the top main panel). The
% Molecular Devices libraries apparently have not been updated since at
% least 2004, and so 32 bit it is. Note that you can still use 64 bit
% Matlab and a 64 bit Windows; only the Multiclamp stuff is 32 bit.
%
% INPUTS
% hWait:            handle to the wait bar window
%
% OUTPUTS
% amplifierInfo:    info list with Multiclamp parameters appended
%
% Last modified: 05/23/2016 (NSD)

global DAQPARS

% start the messaging session
MulticlampTelegraph('start')

% find connected Multielectrode channels. each amplifier has two channels.
ids = MulticlampTelegraph('getAllElectrodeIDS');

% If no Multiclamp amplifier is attached or the Commander isn't open, we
% just return to the calling function.
if isempty(ids)   
    MulticlampTelegraph('stop')
    return
end

% switch directory to the one containing MulticlampControl.exe
oldFolder = ...
    cd([DAQPARS.daqFolder,'\patch_clamp_amplifier\MulticlampControl\Debug']);

idx = 0; 
amplifierInfo = [];
for ii = 1:numel(ids) 

    idx = idx + 1; 
    
    % get basic identification information from amplifier
    chan = MulticlampTelegraph('getElectrodeState',ids(ii));
    name = ['MC', chan.HardwareType(end-3:end)]; % 700A or 700B
    if strcmp(chan.HardwareType(end-3:end),'700A')
        chan.ID = ['COM',num2str(chan.ComPortID)];
        fStr = [name,'_ch',num2str(chan.ChannelID),'_',chan.ID];
        modelNum = 0;
        amplifierID = chan.ComPortID;
    else
        serialNumber = strtok(chan.SerialNumber);
        fStr = [name,'_ch',num2str(chan.ChannelID),'_',serialNumber];
        modelNum = 1;
        amplifierID = serialNumber;
    end
    amplifierInfo(idx).name = fStr; %#ok<*AGROW>
    channelID = chan.ChannelID;
    
    % commands sent to MulticlampControl.exe to put the amplifier
    % in current clamp (CC) or voltage clamp (VC) mode
    cmdCC = ['MulticlampControl.exe ',...
        num2str(modelNum),' ',...
        num2str(amplifierID),' ',...
        num2str(channelID),' 0'];
        
    cmdVC = ['MulticlampControl.exe ',...
        num2str(modelNum),' ',...
        num2str(amplifierID),' ',...
        num2str(channelID),' 1'];    
    
    % update the wait bar window
    if nargin>0
        foo = 0.8/numel(ids);
        waitbar(foo*ii,hWait,['Checking channel ',num2str(ii), '...'])
    end
   
    % first current clamp
    % note that ScaleFactorUnits is always 'V/V' or 'mV/mV' in current
    % clamp, which is why we don't bother checking it
    system(cmdCC);
    chan = MulticlampTelegraph('getElectrodeState',ids(ii));
    amplifierInfo(idx).outputScalingCurrentClamp = ...
        chan.ExtCmdSens * 1E12; % A becomes pA
    amplifierInfo(idx).inputScalingCurrentClamp = ...
        1E3 / chan.ScaleFactor; % V becomes mV 
    
    % then voltage clamp
    system(cmdVC);
    chan = MulticlampTelegraph('getElectrodeState',ids(ii));
    amplifierInfo(idx).outputScalingVoltageClamp = ...
        chan.ExtCmdSens * 1E3; % V becomes mV
    if strcmp(chan.ScaleFactorUnits,'V/nA') % feedback resistor >50 MOhms 
        amplifierInfo(idx).inputScalingVoltageClamp = ...
            (1/chan.ScaleFactor) * 1E3; % nA becomes pA
    elseif strcmp(chan.ScaleFactorUnits,'V/uA') % 50 MOhm feedback resistor
        amplifierInfo(idx).inputScalingVoltageClamp = ...
            (1/chan.ScaleFactor) * 1E6; % uA becomes pA
    end
    
    amplifierInfo(idx).outputScalingOther = 1;
    amplifierInfo(idx).inputScalingOther = 1;
    
    amplifierInfo(idx).detected = true;
    amplifierInfo(idx).ID = ids(ii);
    amplifierInfo(idx).ChannelID = chan.ChannelID;
end

% switch back to original directory
cd(oldFolder)

% stop messaging session
MulticlampTelegraph('stop')





