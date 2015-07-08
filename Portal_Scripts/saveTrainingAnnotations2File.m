%% Jensen_wrapper.m
% This script will save annotations on the portal to a file.  This is
% useful for backing up training data, hand annotated data, etc.

clearvars -except session; 
% clear all; 
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P06-Pipeline'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [7:12,14:34]; % use index value in data key
layerName = 'seizure-linelength-output';  % name of the layer to save to disk
outputDir = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data\Backup_Annots'; % output directory for file

saveAnnotations = 1;  % flag to prevent script from overwriting data accidentally

%% Load investigator data key
switch study
  case 'dichter'
    rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD';
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data';
  case 'jensen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data')); 
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data';
  case 'chahine'
    rootDir = 'Z:\public\DATA\Human_Data\SleepStudies';   % directory with all the data
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P03-Chahine-data';
  case 'pitkanen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P01-Pitkanen-data')); 
end
addpath(genpath(runDir));
fh = str2func(['f_' study '_data_key']);
dataKey = fh();


%% Establish IEEG Sessions
% Establish IEEG Portal sessions.
% Load session if it doesn't exist.
if ~exist('session','var')  % load session if it does not exist
  session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin');
  for r = 2:length(runThese)
    session.openDataSet(dataKey.portalId{runThese(r)});
  end
else    % clear and throw exception if session doesn't have the right datasets
  if (~strcmp(session.data(1).snapName, dataKey.portalId{runThese(1)})) || ...
      (length(session.data) ~= length(runThese))
    clear all;
    error('Need to clear session data.  Re-run the script.');
  end
end
for r = 1: length(session.data)
  fprintf('Loaded %s\n', session.data(r).snapName);
end  


%% Backup annotations 
% clips = {};
timesUsec = [];
channels = {};
labels = {};
if saveAnnotations
  for r = 1:length(runThese)
    fprintf('Getting %s on: %s\n', layerName, session.data(r).snapName);
    % get annotations
    try
      [allEvents, timesUsec, channels] = f_getAllAnnots(session.data(r), layerName);
      labels = {allEvents.description}';

      % save to mat file
      clipsFile = fullfile(outputDir, sprintf('%s-backupAnnot-%s.mat',session.data(r).snapName,layerName));
      if exist(clipsFile, 'file');
        a = input(sprintf('%s exists: proceed? y/n: ', clipsFile), 's');
      else
        a = 'y';
      end
      if strcmpi(a, 'y')
        save(clipsFile, 'timesUsec', 'channels', 'labels', '-v7.3');
        fprintf('Saved %s.\n', clipsFile);
      end
    catch err
      if isempty(find(strcmp({session.data(r).annLayer(:).name}, layerName),1))
        fprintf('Check layer %s exists in dataset %s.\n', layerName, session.data(r).snapName);
      else
        rethrow(err);
      end
    end
  end
else
  fprintf('No annotations saved: change saveAnnotations to 1.\n');
end


