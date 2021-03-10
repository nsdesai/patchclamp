function [ahp,ahpLatency,ahpHalfWidth,ahpThirdWidth] = calculateahp(data,locs,thrs,dt)

locs = round(locs/dt);
spikewidth = round(2/dt);

if numel(locs)>1
    data = data(locs(1)+spikewidth:locs(2)-spikewidth);
else
    data = data(locs(1)+spikewidth:end);
end
xdata = (1:length(data))*dt - dt;
data = smooth(xdata,data,0.1,'loess');
[minV,idx] = min(data);

ahp = thrs(1)-minV;

ahpLatency = idx*dt + spikewidth;

ahpHalf = thrs(1) - ahp/2;
idx = find(data < ahpHalf);
ahpHalfWidth = xdata(max(idx)) - xdata(min(idx));

ahpThird = thrs(1) - ahp*2/3;
idx = find(data < ahpThird);
ahpThirdWidth = xdata(max(idx)) - xdata(min(idx));


