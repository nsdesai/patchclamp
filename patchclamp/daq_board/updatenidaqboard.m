function [updateBoard] = updatenidaqboard(channelStatusOld,channelStatusNew,outputChannelsOld,outputChannelsNew)

updateBoard = false;
for ii = 1:numel(channelStatusOld)
    if strcmp(channelStatusOld{ii},'off') && ~strcmp(channelStatusNew{ii},'off')
        updateBoard = true;
        return
    end
    if ~strcmp(channelStatusOld{ii},'off') && strcmp(channelStatusNew{ii},'off')
        updateBoard = true;
        return
    end
end

if nargin < 3
    return
end

if isequal(outputChannelsOld,outputChannelsNew)
    return
else
    updateBoard = true;
end

