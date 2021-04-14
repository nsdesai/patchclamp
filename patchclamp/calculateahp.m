function [ahp,ahpLatency,ahpHalfWidth,ahpThirdWidth,ahpSlope] = calculateahp(data,locs,thrs,dt)

locs = round(locs/dt);
locs(locs==0) = [];
spikewidth = round(2/dt);

if numel(locs)>1
    data = data(locs(1)+spikewidth:locs(2)-spikewidth);
else
    data = data(locs(1)+spikewidth:end);
end
xdata = (1:length(data))*dt - dt;
data = smooth(xdata,data,0.1,'loess');
[minV,idxV] = min(data);

ahp = thrs(1)-minV;

ahpLatency = idxV*dt + spikewidth;

ahpHalf = thrs(1) - ahp/2;
idx = find(data < ahpHalf);
if numel(idx)>1
    ahpHalfWidth = xdata(max(idx)) - xdata(min(idx));
else
    ahpHalfWidth = [];
end

ahpThird = thrs(1) - ahp*2/3;
idx = find(data < ahpThird);
if numel(idx)>1
    ahpThirdWidth = xdata(max(idx)) - xdata(min(idx));
else
    ahpThirdWidth = [];
end

data = data(idxV:idxV+round(50/dt));
times = (1:length(data))*dt - dt;
dvdt = diff(data)/dt;
ahpSlope(1) = max(dvdt);
p = polyfit(times,data,1);
ahpSlope(2) = p(1);
ahpSlope = ahpSlope(:);





