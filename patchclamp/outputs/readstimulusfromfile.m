function stimulus = readstimulusfromfile(amplitude,N)
% function stimulus = readstimulusfromfile(amplitude,N)
%
% When this function is called, the outputs specified in a line of the ni
% GUI come from a MAT or text file written to disk. (MAT files end in
% '.mat' and we assume here that text files end in '.txt'). Data to be used
% as the output should be column in an ASCII file (for text) or included in
% the first variable stored in the MAT file. When the first MAT variable is
% a matrix, the columns are concatenated.
%
% INPUTS
% amplitude:    expression entered in the amplitude field
% N:            the number of elements of the data to be included as output
%
% OUTPUTS
% stimulus:     the stimulus (pA in current clamp, mV in voltage
%               clamp, V otherwise) sent as output by ni
%
% modified 12/21/16 by NSD

dotPoint = strfind(amplitude,'.mat'); isMAT = true;
if isempty(dotPoint)
    dotPoint = strfind(amplitude,'.txt');
    isMAT = false;
end

fileName = amplitude(1:dotPoint+3);
lengthName = length(fileName) - 4; % excluding .mat or .txt 
foundFile = false;
while lengthName > 0
    foundFile = exist(fileName,'file');
    if foundFile
        firstPoint = strfind(amplitude,fileName);
        break
    end
    fileName = fileName(2:end);
end

% if we cannot find file, just return zeros
if ~foundFile, stimulus = zeros(N,1); return, end

try
if isMAT
    data = load(fileName);
    fn = fieldnames(data); fn = fn{1}; % the first variable encountered
                                       % is assumed to contain the data
    data = eval(['data.',fn]);
else
    data = importdata(fileName);
end
catch
    msg = 'No MAT or TXT file by that name found.';
    error(msg)
end

% if there are multiple columns, they are concatenated
data = data(:);  %#ok<NASGU>

% evaluate the expression, replacing fileName with data
amplitude = [amplitude(1:firstPoint-1),'data',amplitude(dotPoint+4:end)];
data = eval(amplitude);

stimulus = zeros(N,1);
if numel(stimulus)>=N
    stimulus = data(1:N);
else
    stimulus(1:numel(data)) = data;
end
    
% error catching -- delete after 12/20/16
stimulus(stimulus<-100) = -100;



