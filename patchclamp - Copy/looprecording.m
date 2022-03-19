function [tempFile,fileName,triggerTime] = looprecording(ax,ax1,output1,inputGains,colors,popup)

global DAQPARS stopBackground %#ok<GVMIS>

dt = 1000/DAQPARS.sampleRate;

warning('off','MATLAB:subscripting:noSubscriptsSpecified');
cla(ax(1)); cla(ax(2))
hold(ax(1),'on'); hold(ax(2),'on')
for iCount = 1:numel(DAQPARS.inputChannels)
    plotHandle(iCount) = plot(ax(ax1(iCount)), ...
        dt:dt:DAQPARS.duration,...
        NaN(length(output1),1),...
        'color',colors(DAQPARS.inputChannels(iCount),:)); %#ok<AGROW>
end
hold(ax(1),'off'); hold(ax(2),'off')
if ~popup
    xlim(ax(1),[0 DAQPARS.duration]);
    xlim(ax(2),[0 DAQPARS.duration]);
    axis 'auto y'
end

ydata = NaN(length(output1),numel(DAQPARS.inputChannels));
fileName = [DAQPARS.saveDirectory,filesep,'temp',filesep,'tempName.bin'];
tempFile = fopen(fileName, 'w');

preload(DAQPARS.daqObj, output1)
N = ceil(DAQPARS.sampleRate/10); % minimum number to trigger ScansAvailableFcn
DAQPARS.daqObj.ScansAvailableFcnCount = N;
DAQPARS.daqObj.ScansAvailableFcn = @(src,evt) plotinputsloop(src,evt);
plotoutputs(1)
triggerTime = now;
start(DAQPARS.daqObj,'repeatoutput')

pause(0.1)
while DAQPARS.daqObj.Running
    if stopBackground
        stop(DAQPARS.daqObj)
        break
    end
    drawnow limitrate
end
set(DAQPARS.MainApp.startButton,'Text','start')

    function [] = plotinputsloop(obj,~)  
        data = read(obj,obj.ScansAvailableFcnCount,"OutputFormat","Matrix");
        data = data ./ repmat(inputGains,size(data,1),1);
        n1 = size(data,1);
        for jCount = 1:size(data,2)
            data1 = data(:,jCount);
            ydata = circshift(ydata,n1);
            ydata(1:n1) = data1(end:-1:1);
            set(plotHandle(jCount),'YData',ydata)
        end
        fwrite(tempFile,data,'double');
    end

end


