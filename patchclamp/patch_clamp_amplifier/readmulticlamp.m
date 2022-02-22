function [] = readmulticlamp(app)
global DAQPARS

cmdPreamble = [DAQPARS.daqFolder,'\patch_clamp_amplifier\MulticlampControl\Debug\MulticlampControl.exe '];
MulticlampTelegraph('start')
hWait = waitbar(0.2,'Please wait as we read amplifiers ...');

DAQPARS.multiclampHolding = zeros(DAQPARS.nChannels,1);

for ii = 1:numel(DAQPARS.amplifierIdx)
    
    s = ['statusDropDown_',num2str(ii)];
    g = ['gainDropDown_',num2str(ii)];
    h = ['holdingEditField_',num2str(ii)];

    if app.(s).Enable==false
        continue
    else
        results{ii} = []; %#ok<AGROW> 
    end
    
    idx = DAQPARS.amplifierIdx(ii);
    if idx > 4, continue, end   % ignore manual settings
    ID = DAQPARS.amplifierInfo(idx).ID;
    chan = MulticlampTelegraph('getElectrodeState',ID);
    switch chan.OperatingMode
        case 'V-Clamp'
            app.(s).Value = 'voltage clamp';
        case 'I-Clamp'
            app.(s).Value = 'current clamp';
        case 'I = 0'
            app.(s).Value = 'I=0';
    end
    app.(g).Value = num2str(chan.Alpha);
    % name will be like MC700A_ch1_COM3 or MC700B_ch2_38482
    % the last entry is the COM port for 700A and the serial
    % number of 700B (in demo mode, the latter is "Demo")
    name = DAQPARS.amplifierInfo(idx).name;
    % model = '0' means 700A, model = '1' means 700B
    if strcmp(name(6),'B'), model = '1'; else model = '0'; end %#ok<*SEPEX>
    if strcmp(model,'0')
        amplifierID = name(15);
    else
        amplifierID = name(12:end);
    end
    channelID = name(10);
    cmd = [cmdPreamble, model,' ',amplifierID,' ',channelID,' 7 '];
    [~,result] = system(cmd);
    % result is in this format:
    % 'mode_gain_holdingEnable_holding_capEnable_cap_bridgeEnable_bridge,1,1,0,1.00251e-10,1,0,0,0'
    result = strsplit(result,',');
    if strcmp(result{4},'1')  % holding is enabled in Commander
        holding = str2double(result{5});
        ampMode = str2double(result{2}); % 0 voltage clamp, 1 current clamp, 2 I=0
        if ampMode==0     % voltage clamp
            holding = holding*1000;     % convert holding potential from V to mV
        elseif ampMode==1   % current clamp
            holding = holding*10^12;    % convert current from A to pA
        else    % I=0
            holding = 0;
        end
    else
        holding = 0;
    end
    app.(h).Value = holding;
    DAQPARS.multiclampHolding(ii) = holding;
    results{ii} = result; %#ok<AGROW> 
    waitbar(ii*0.2+0.2,hWait,'Please wait as we read amplifiers ...');
    
end

close(hWait)
MulticlampTelegraph('stop')

updateparameters(app,results)
