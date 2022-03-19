function [] = turnonholding(app,channelNum)
global DAQPARS %#ok<*GVMIS> 

testPulseOn = app.TestPulse;

if ~strcmp(DAQPARS.channelStatus(channelNum),'voltage clamp')
    disp('adding holding potential only works for voltage clamp')
    return
end

if testPulseOn==true  % turn off test pulse momentarily
   pushTestButton(app);
end

fStr = ['holdingEditField_',num2str(channelNum)];
app.(fStr).Value = -65;
updateparameters(app)

cmdPreamble = [DAQPARS.daqFolder,'\patch_clamp_amplifier\MulticlampControl\Debug\MulticlampControl.exe '];
gain = DAQPARS.channelGain(channelNum);
holding = DAQPARS.channelHolding(channelNum);
idx = DAQPARS.amplifierIdx(channelNum);
if idx > 4, return, end   % ignore manual settings
% name will be like MC700A_ch1_COM3 or MC700B_ch2_38482
% the last entry is the COM port for 700A and the serial
% number of 700B (in demo mode, the latter is "Demo")
name = DAQPARS.amplifierInfo(idx).name;
% model = '0' means 700A, model = '1' means 700B
if strcmp(name(6),'B'), model = '1'; else model = '0'; end %#ok<SEPEX> 
if strcmp(model,'0')
    amplifierID = name(15);
else
    amplifierID = name(12:end);
end
channelID = name(10);
cmd = [cmdPreamble, model,' ', amplifierID,' ',...
    channelID,' 3 ',num2str(gain),' ', ...
    num2str(holding)];
system(cmd);

if testPulseOn==true        % turn test pulse on again
    pushTestButton(app);
end
