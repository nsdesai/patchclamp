function [ahp,ahpLatency] = calculateahp(data,locs,thrs,dt)

locs = round(locs/dt);

if numel(locs)>1
    [minV,idx] = min(data(locs(1):locs(2)));
else
    [minV,idx] = min(data(locs(1):end));
end

ahp = thrs(1)-minV;

ahpLatency = idx*dt;
