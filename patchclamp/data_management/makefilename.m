function [] = makefilename(~)
global DAQPARS
% function [] = makefileName(~)
%
% When called without an argument, the function simply uses updated
% experiment (eNo) and trial (tNo) numbers to update the filename. When
% called with an argument (when the program is first started), it also
% makes sure that the file name does not already exist in the save
% directory.

% eNo is experiment number. tNo is trial number
eNo = num2str(DAQPARS.experimentNo,'%03i');
tNo = num2str(DAQPARS.trialNo,'%03i');
fileName = ['experiment',eNo,'trial',tNo];

if nargin   % when GUI is started, make sure filename does not already ...
            % exist
    matFiles = dir([DAQPARS.saveDirectory,'experiment*.mat']);
    baz = 0;
    for iCount = 1:numel(matFiles)
        foo = matFiles(iCount).name;
        boo = strfind(foo,'t');
        bar = str2double(foo(boo(1)+1:boo(2)-1));
        if bar>baz, baz=bar; end
    end
    DAQPARS.experimentNo = max(1,baz+1);
    DAQPARS.MainApp.experimentNumberEditField.Value = num2str(DAQPARS.experimentNo);
    eNo = num2str(DAQPARS.experimentNo,'%03i');   
    fileName = ['experiment',eNo,'trial',tNo];
end

DAQPARS.fileName = fileName;

