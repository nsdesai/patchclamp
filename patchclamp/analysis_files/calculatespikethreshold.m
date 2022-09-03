function thresholds = calculatespikethreshold(data,dt,l)

dvdtThreshold = 10; % 10 mV/msec

locs = round(l/dt);

thresholds = NaN(numel(locs),1);
for ii = 1:numel(locs)
    back = max(locs(ii) - round(3/dt),1);
    data1 = data(back:locs(ii));
    dvdt = diff(data1)/dt;
    dvdtLoc = find(dvdt>=dvdtThreshold,1);
    if isempty(dvdtLoc)
        thresholds(ii) = NaN;
    else
        thresholds(ii) = data1(dvdtLoc);
    end
end
