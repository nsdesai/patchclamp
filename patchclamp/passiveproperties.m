function [Vm,Rn,tau] = passiveproperties(data,params)

current = params.current;
dt = params.dt;

Vm = mean(data(1:params.pulsePts(1)-1));
deflection = mean(data(params.pulsePts(2)-round(10/dt):params.pulsePts(2)-1)) - Vm;
Rn = abs(1000*deflection/current); % megaohms

ydata = data(params.pulsePts(1):params.pulsePts(2)-round(50/dt));
xdata = (1:length(ydata))*dt - dt;
startPt = mean(ydata(1:5));
endPt = mean(ydata(end-4:end));
tauGuess = max(0.01,(xdata(end)-xdata(1))/3); % assume three time constants are included in fit
xdata1 = xdata - xdata(1);
fitType = fittype('a-b*exp(-c*x)');
f0 = fit(xdata1(:),ydata(:),fitType,'StartPoint',[endPt,endPt-startPt,1/tauGuess]);
tau = 1/f0.c;
