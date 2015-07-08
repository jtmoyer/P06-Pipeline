% This script will move annotations made on one layer to another layer.
% The annotations should have some text pattern that identifies which ones
% to move - ie, EEGstart, EEGstop - use 'EEG'
% This script will overwrite the old layer with the existing annotations,
% minus the ones that have been moved to the new layer.  Script will also
% add the new layer with the desired annotations.

clearvars -except session; 
close all; 
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P06-Pipeline\'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [1,3:5,7:12,14:34]; % index of animals in data key

origLayerName = 'seizure-linelength-start-stop'; % name of existing layer, move annots from here
newLayerName = 'seizure-linelength'; % name of new layer, move annots to here
textPattern = 'seizure'; % text common to all annotations you want moved

switchAnnotations = 0; % flag to prevent script from running accidentally

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
%   session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin','qa');
  for r = 2:length(runThese)
%     runThese(r)
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
%   fprintf('Loaded %s\n', session.data(r).snapName);
end  


%% Feature detection and annotation upload 
if switchAnnotations
  a = input(sprintf('Do you really want to move ''%s'' annotations from %s to %s? (y/n): ', textPattern, origLayerName, newLayerName), 's');
  if strcmpi(a, 'y')
    for r = 1:length(runThese)
      try
        [allEvents, timesUSec, channels] = f_getAllAnnots(session.data(r), origLayerName);
        labels = {allEvents.description}';
        matches = cellfun(@regexpi, labels, cellstr(repmat(textPattern, length(labels),1)),'UniformOutput',false);
        idx = ~cellfun(@isempty, matches);  % 1 in idx will be moved to new layer
      catch err
        idx = [];
        rethrow(err);
        fprintf('%s: %s not found.\n', session.data(r).snapName, origLayerName);
      end
%       labels = {allEvents.description}';
      if ~isempty(find(idx,1))
        % some of the start/annotations are really short, make them 1 sec long
        tooShort = (timesUSec(:,2) - timesUSec(:,1)) < 1e6;
        timesUSec(logical(idx.*tooShort),2) = timesUSec(logical(idx.*tooShort),1) + 1e6;
        f_uploadAnnotations(session.data(r), newLayerName, timesUSec(idx,:), channels(idx), labels(idx));
        f_uploadAnnotations(session.data(r), origLayerName, timesUSec(~idx,:), channels(~idx), labels(~idx));
        fprintf('Moved %d annotations from %s to %s on: %s\n', length(find(idx)), origLayerName, newLayerName, session.data(r).snapName);
      else
        fprintf('%s: No annotations moved.\n', session.data(r).snapName);
      end
    end
  else
     fprintf('%s: No annotations moved.\n', session.data(r).snapName);
  end
end

