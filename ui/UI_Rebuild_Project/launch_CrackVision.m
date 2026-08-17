%% Launch CrackVision
% Run this script from MATLAB R2026a. The app object remains available as
% `app` in the base workspace.

delete(findall(groot, 'Type', 'figure', 'Name', 'CrackVision'));
clear CrackVisionApp classicalCrackBaseline sauvolaThreshold
clear predictCrackEnsemble predictCrackEnsembleAdaptive

uiFolder = fileparts(mfilename('fullpath'));
addpath(uiFolder);
app = CrackVisionApp;
