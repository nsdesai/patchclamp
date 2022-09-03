function [] = plotinputs(obj,~,inputGains,plotHandle)
% function [] = plotcontinuous(obj,~,inputGains,isPressure,plotHandle)

global plottingCounter

data = read(obj,obj.ScansAvailableFcnCount,"OutputFormat","Matrix");
data = data ./ repmat(inputGains,size(data,1),1);
lenData = length(data);
for iCount = 1:size(data,2)
    data1 = data(:,iCount);
    ydata = get(plotHandle(iCount),'YData');
    ydata(1+(plottingCounter-1)*lenData:plottingCounter*lenData) = data1';
    set(plotHandle(iCount),'YData',ydata)
end
plottingCounter = plottingCounter + 1;
