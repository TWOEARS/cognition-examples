% This script initialises the path variables that are needed for running
% the Two!Ears feedback and attention module

basePath = fileparts(mfilename('fullpath'));

% Add all relevant folders to the matlab search path

addpath(fullfile(basePath, '../environmentalData/'));
addpath(fullfile(basePath, '../environmentalData/scenarioA/'));
addpath(fullfile(basePath, '../knowledgeSources'));
addpath(fullfile(basePath, '../hypotheses'));
addpath(fullfile(basePath, '../aux'));
addpath(fullfile(basePath, '../aux/Astar'));


clear basePath;
