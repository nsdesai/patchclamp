function [amplifierOkay] = amplifiercommands(cmd,bridge,dc,testSignal)
% function [amplifierOkay] = amplifiercommands(cmd,bridge,dc)
%
% This function works only for Multiclamp 700A/700B amplifiers.
%
% DAQPARS.amplifierInfo contains data on all available amplifiers. 
% DAQPARS.amplifierIdx indicates to which amplifiers the first four analog
% input channels of the National Instruments board are connected. And a
% number in makefixedparametersfile.m indicates which channel is being
% used by the automated patch clamp system (usually 1, which is 
% called ai0 under National Instruments nomenclature). So the amplifier
% data are contained in: 
%
%       DAQPARS.amplifierInfo(DAQPars.amplifierIdx(channelNumber))
%
% where, again, channelNumber is usually 1.
%
% INPUTS
% cmd:      ready         put amplifier in voltage clamp with a gain of 1 
%                         and holding potential zero
%           zero          zero the pipette offset
%           cap           run the amplifier's automatic fast and slow
%                         capacitance neutralization routines
%           Izero         put amplifier in (I=0) current clamp with gain 10     
%           recording     put amplifier in current clamp with a gain of 10 
%                         and zero holding current
%           measure       put amplifier in voltage clamp with a gain of 1
%                         and a holding potential of -70
%           information   returns information about amplifier state
% bridge    when in current clamp, the series resistance (MOhms) to use for
%           for bridge balance
% dc        steady current (pA) to inject in current clamp
%
% OUTPUTS
% amplifierOkay        true            no errors
%                      false           errors
% result               output from MulticlampControl.cpp
%
% Last modified: March 2, 2017 (NSD)


global APPARS DAQPARS
persistent ampInfo

% get amplifier information
if isempty(APPARS)
    APPARS.fixedParametersFile = matfile('fixed_parameters.mat');
end
if ~exist('ampInfo','var') || isempty(ampInfo)
    p = APPARS.fixedParametersFile.DaqAutomated;
    channelNum = p.channels.electrodeInput;
    ampInfo = DAQPARS.amplifierInfo(DAQPARS.amplifierIdx(channelNum));
end

% the necessary amplifier information is contained in its name, which will
% be organized like this:
%       ampInfo.name = 'MC700B_ch1_234242332';
% or 
%       ampInfo.name = 'MC700A_ch1_COM4';
% where the first part indicates whether the Multiclamp is 700A or 700B,
% the second whether we are using channel 1 or channel 2 (n.b., the
% amplifier channels are different than the National Instrument board
% channels), and the third the amplifier's identifier. For 700A, the 
% identifier is the number of the COM port. For 700B, the identifier is a
% special serial number.
slashLoc = strfind(ampInfo.name,'_');
if strcmp(ampInfo.name(slashLoc(1)-1),'A')
    mcModelNum = '0';
else 
    mcModelNum = '1';
end
mcChannelNum = ampInfo.name(slashLoc(1)+3:slashLoc(2)-1);
if strcmp(mcModelNum,'0')
    mcIdentifier = ampInfo.name(slashLoc(2)+4:end); % 4 rather than 1 to
    												% discard the COM part
else
    mcIdentifier = ampInfo.name(slashLoc(2)+1:end); 
end


% to control the Multiclamp amplifier, we use an executable 
% (MulticlampControl.exe) created in Visual Studio 2015 using the
% SDK offered by Molecular Devices and last modified in 2004 (!).
% To understand how the command string (mcCmd) is organized, read the 
% comments at the top of MulticlampControl.cpp.

% select between the available options
executableLocation = [DAQPARS.daqFolder,...
    '\patch_clamp_amplifier\MulticlampControl\Debug\'];
mcCmdPreamble = [executableLocation,'MulticlampControl.exe ',...
    mcModelNum,' ',mcIdentifier,' ',mcChannelNum,' '];
switch cmd
    
    case 'ready'

        mcGain = '1';
        mcHoldingPotential = '0'; % mV
        mcCmd = [mcCmdPreamble,'3 ',mcGain,' ',mcHoldingPotential];    
    
    case 'zero'
        
        mcCmd = [mcCmdPreamble,'5'];
        
    case 'cap'
        
        mcCmd = [mcCmdPreamble,'4'];
        
    case 'Izero'
        
        mcGain = '10';
        mcCmd = [mcCmdPreamble,'6 ',mcGain];
        
    case 'recording'
        
        mcGain = '10';
        if exist('bridge','var')
            mcBridgeBalance = num2str(bridge);
        else
            mcBridgeBalance = '0'; % MOhms
        end
        mcCapNeutralization = '1'; % pF
        if exist('dc','var')
            mcHoldingCurrent = num2str(dc);
        else
            mcHoldingCurrent = '0'; % pA
        end
        mcCmd = [mcCmdPreamble,'2 ',mcGain,' ',mcBridgeBalance,' ',...
            mcCapNeutralization,' ',mcHoldingCurrent];
        
    case 'measure'
        
        mcGain = '1';
        mcHoldingPotential = '-70'; % mV
        mcCmd = [mcCmdPreamble,'3 ',mcGain,' ',mcHoldingPotential];
        
    case 'information'
        
        mcCmd = [mcCmdPreamble,'7'];
        
    case 'testSignal'
        
        mcCmd = [mcCmdPreamble,'8 ',testSignal];
        
    otherwise
end

% do it
[status,result] = system(mcCmd); %#ok<ASGLU>

% if all goes well, status will be 1. Otherwise, it will be something else.
if status==1
    amplifierOkay = true;
else
    amplifierOkay = false;
end
