function Rn = inputresistance(data,currents,hyperIdx,params)

dt = params.dt;

data = data(:,1:hyperIdx);
currents = currents(1:hyperIdx);

deflection = NaN(numel(currents),1);
for ii = 1:numel(currents)
    baseline = mean(data(1:params.pulsePts(1)-1,ii));
    endValue = mean(data(params.pulsePts(2)-round(10/dt):params.pulsePts(2)-1,ii)); 
    deflection(ii) = endValue - baseline;
end
deflection(end+1) = 0;
currents(end+1) = 0;

p = polyfit(currents,deflection,1);

Rn = p(1)*1000; % megaohms

