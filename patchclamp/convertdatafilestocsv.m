function [] = convertdatafilestocsv(fileName,folderName)

load(fileName,'Pars','inputData','outputData')

if nargin<2
    folderName = pwd;
end

% arguments: sample points, steps/sweeps, output channel (if more than 1) 
outputData = outputData(:,Pars.orderOfSteps,:);

inputChannels = Pars.inputChannels;

foo = datestr(Pars.time,30);
yr = foo(1:4);
mo = foo(5:6);
dy = foo(7:8);
newFolder = [folderName,filesep,yr,filesep,mo,filesep,dy];
newFolder = [newFolder,filesep,Pars.fileName(1:13)];
if ~exist(newFolder,'dir')
    mkdir(newFolder)
end

for ii = 1:numel(inputChannels)
    chan = inputChannels(ii);
    newFileName = [Pars.fileName(14:21),'_channel',num2str(chan)];
    dataInput = inputData(:,:,ii);
    [boo,bar] = ismember(Pars.inputChannels,Pars.outputChannels);
    if ~isempty(boo)
        dataOutput = outputData(:,:,bar);
    end
    status = Pars.channelStatus{chan};
    switch status
        case 'voltage clamp'
            newFileNameInput = [newFileName,'_I_INPUT.csv'];
            newFileNameOutput = [newFileName,'_V_OUTPUT.csv'];
        case 'current clamp'
            newFileNameInput = [newFileName,'_V_INPUT.csv'];
            newFileNameOutput = [newFileName,'_I_OUTPUT.csv'];
        case 'field potential'
            newFileNameInput = [newFileName,'_F_INPUT.csv'];
            newFileNameOutput = [];
    end
    fStr = [newFolder,filesep,newFileNameInput];
    writematrix(dataInput,fStr);
    if ~isempty(newFileNameOutput)
        gStr = [newFolder,filesep,newFileNameOutput];
        writematrix(dataOutput,gStr);
    end
end


    

