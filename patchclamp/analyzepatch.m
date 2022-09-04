function [] = analyzepatch
global analysisFolder %#ok<GVMIS> 

% add all the folders
analysisFolder = [userpath,filesep,'patchclamp',filesep,'analysis_files'];
assert(isfolder(analysisFolder),...
    'The folder containing the analysis files could not be found.')
addpath(genpath(analysisFolder))
filtersFolder = [userpath,filesep,'patchclamp',filesep,'filters'];
addpath(genpath(filtersFolder))


LCSMS_analysis


