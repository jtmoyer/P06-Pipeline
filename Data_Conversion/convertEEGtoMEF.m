%% Dichter_convert.m
% this script will read data from .eeg files (Nicolet format) and convert
% it to .mef format.  The script uses the f_eeg2mef function, which assumes
% data is stored in eeg files in a directory with this kind of path:
% Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000\r097_000.eeg
% output files will be written to ...\DichterMAD\mef\Dichter_r097_01.mef
% for channel 1, ...02.mef for channel 2, etc.

clear all; 
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
javaaddpath('C:\Users\jtmoyer\Documents\MATLAB\java_MEF_writer\MEF_writer.jar');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

% define constants for conversion
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [19:34]; % see dataKey indices
dataBlockLenHr = 0.1; % hours; size of data block to pull from .eeg file
mefGapThresh = 10000; % msec; min size of gap in data to be called a gap
mefBlockSize = 10; % sec; size of block for mefwriter to write

convert = 1;  % convert data y/n?
test = 0;     % test data y/n?


%% Load investigator data key
switch study
  case 'dichter'
    rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD';
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data';
  case 'jensen'
   rootDir = 'Z:\public\DATA\Animal_Data\Frances_Jensen'; % directory with all the data
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


%% convert data from EEG to mef
if convert
  for r = 1: length(runThese)
    animalDir = fullfile(rootDir,char(dataKey.animalId(runThese(r))),'2000Hz');
    f_eeg2mef(animalDir, dataBlockLenHr, mefGapThresh, mefBlockSize);
  end
end


%% compare converted files (on portal) to original
if test
  if ~exist('session','var')  % load session if it does not exist
    session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin','qa');
    for r = 2:length(runThese)
      runThese(r)
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

  for r = 1: length(runThese)
    animalDir = fullfile(rootDir,char(dataKey.animalId(runThese(r))),'2000Hz');
    f_test_eeg2mef(session.data(r), animalDir, dataBlockLenHr);
  end
end

