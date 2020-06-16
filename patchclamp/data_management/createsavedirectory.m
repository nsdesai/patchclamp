function [] = createsavedirectory
% function [] = createsavedirectory
%
% The function creates a directory within the Matlab work folder in which
% to save data.

global DAQPARS

foo = date;                         % data are organized in a group of
year = foo(8:11);                   % nested folders: first year, then
month = foo(4:6);                   % month, then day
day = foo(1:2);                     % (e.g., '2011\Nov\09' is
                                    % a possible directory)
                                    
base = userpath; 

base(end+1) = '\';
directoryName = [base,year,'\',month,'\',day];
if ~exist(directoryName,'dir')
    mkdir(directoryName)
end

tempDirectoryName = [directoryName,'\temp'];
if ~exist(tempDirectoryName,'dir')
    mkdir(tempDirectoryName)
end

DAQPARS.saveDirectory = [directoryName,'\'];

