clearvars -except session; 
% clear all;  
close all; 
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [1:34]; 

removeAnnotations = 0;
layerName = 'seizure-linelength-start-stop-grooming-artifacts';

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
if removeAnnotations
  a = input(sprintf('Do you really want to remove the layer %s? (y/n): ', layerName), 's');
  if strcmpi(a, 'y')
    for r = 1:length(runThese)
      try
%         if ~isempty(session.data(r).annLayer(strcmp(layerName,{session.data(r).annLayer.name})))
        session.data(r).removeAnnLayer(layerName);
        fprintf('Removed %s on: %s\n', layerName, session.data(r).snapName);
%         end
      catch
        fprintf('%s: %s not found.\n', session.data(r).snapName, layerName);
      end
    end
  else
     fprintf('%s: %s. No annotations removed.\n', session.data(r).snapName, layerName);
  end
end

