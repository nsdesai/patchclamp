function varargout = convertdatafilestoascii(fileName,folderName)

load(fileName,'Pars','inputData','outputData')

if nargin<2
    folderName = pwd;
end

% arguments: sample points, steps/sweeps, output channel (if more than 1) 
outputData = outputData(:,Pars.orderOfSteps,:);
outputChannels = Pars.outputChannels;

inputChannels = Pars.inputChannels;
inputStatus = Pars.channelStatus;

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
    newFileName = [Pars.fileName(14:21),'_channel_',num2str(chan)];
    data = inputData(:,:,ii);
    status = Pars.channelStatus{chan};
    switch status
        case 'voltage clamp'
            newFileNameInput = [newFileName,'_I_INPUT.txt'];
            newFileNameOutput = [newFilename,'_V_OUTPUT.txt'];
        case 'current clamp'
            newFileNameInput = [newFileName,'_V_INPUT.txt'];
            newFileNameOutput = [newFilename,'_I_OUTPUT.txt'];
    end
    varargout{2*ii-1} = data;

    

