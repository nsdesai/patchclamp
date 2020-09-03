function result = zerotestpulse(app)
global DAQPARS

cmdPreamble = [DAQPARS.daqFolder,'\patch_clamp_amplifier\MulticlampControl\Debug\MulticlampControl.exe '];

channelIdx = find(app.UITestPulse.Data);
if isempty(channelIdx)
    result = 0;
    return
end

results = zeros(numel(channelIdx),1);
for ii = 1:numel(channelIdx)

    chan = channelIdx(ii);

    idx = DAQPARS.amplifierIdx(chan);
    if idx > 4, continue, end   % ignore manual settings
    
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

    cmd = [cmdPreamble, model,' ',amplifierID,' ',channelID,' 5'];
    
    results(ii) = system(cmd);  % if all goes well, result = 1
    
    if results(ii)==1
        fStr = ['holdingEditField_',num2str(chan)];
        app.(fStr).Value = 0;
        updateparameters(app)
    end 
    
end

result = mean(results); % if all goes well, result = 1
