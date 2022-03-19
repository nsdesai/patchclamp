function [ydata,yStr] = otherbasicproperties(analysisType,pks,locs,wds,thrs)

yStr = '';

switch analysisType
    case 'ISI'
        locs(locs==0) = [];
        ydata = diff(locs);
        yStr = 'interspike interval (ms)';
        
    case 'spike threshold'
        ydata = thrs;
        yStr = 'spike threshold (mV)';
        
    case 'spike width'
        ydata = wds;
        ydata(ydata==0) = NaN;
        yStr = 'spike width (ms)';
        
    case 'spike height'
        ydata = pks;
        ydata(ydata==0) = NaN;
        yStr = 'spike height (mV)';

    otherwise
        
end

