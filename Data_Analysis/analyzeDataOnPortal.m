%% analyzeDataOnPortal.m
% Use this script to interact with and analyze datasets on the portal.
% This is referred to throughout the documentation as the IEEG Pipeline.
%
% The algorithm is intended to be used as follows:
%   -> perform initial event detection - calculate a simple feature using a
%     sliding window and look for places where the feature crosses a
%     threshold for a minimum amount of time
%
%   -> upload these initial event detections back to the portal
%
%   -> manually review the detections on the portal and tune the initial
%     event detections (threshold and minimum duration)
%
%   -> create a test data set using the initial detections - this data set
%     will include both events and artifacts
%
%   -> upload these test detections to the portal as a separate layer
%
%   -> perform artifact removal on the initial event detections - define
%     a given feature and identify a threshold to separate events from 
%     artifacts.  This can be tuned to optimize performance on the test
%     dataset
%
%   -> upload remaining detections to the portal as a final output layer
%
% Jason Moyer & Hoameng Ung 7/20/2015 
% University of Pennsylvania Center for Neuroengineering and Therapeutics
%
% History:
% 7/20/2015 - v1 - creation
%.............

clearvars -except session;
close all force; clc; tic;
params.homeDirectory = 'C:\Users\jtmoyer\Documents\MATLAB\';


%% Define constants and parameters for the analysis
% Parameters which are frequently adjusted are included here.  Less
% frequently used parameters are loaded in f_setEnvironment().
params.study = 'jensen';       % string indicating which dataset to analyze, ie 'jensen'
params.runThese = [1:5,7:12,14:34]; % [1:5,7:12,14:34] [1:5,7:9] [10:12,14:18] [19:26] [27:34];        % which datasets to run, use indices in dataKey.index 
params.channels = 1:4;         % which channels to analyze
params.runInParallel = 0;
params.maxParallelPools = 8;

params.initialDetection = 0;     % run initial event detection? 0/1
params.feature = 'linelength';   % feature to use for initial event detection
params.initialOutputLayer = ['initial-' params.feature];
params.startTime = '2:22:37:10'; % day:hour:minute:second, in portal time
params.endTime = '2:22:38:00';   % day:hour:minute:second, in portal time
params.minThresh = 2e2;       % minimum threshold for initial event detection
params.minDur = 5;           % sec; minimum duration for detections
params.viewInitialDetectionPlot = 1; % view plot of feature overlaid on signal, 0/1

params.scoreDetections = 0;   % create and hand-score a test dataset, requires initial event detections
params.numDetections = 200;   % number of detections tp generate for test dataset
% params.scoringInputLayer = 'seizure-linelength';
params.scoringOutputPrefix = 'testing';   % prefix for testing data layer

params.artifactRemoval = 0;   % remove artifacts from detections
params.finalOutputLayer = 'seizure-linelength-output';
params.lookAtArtifacts = 0;   % lookAtArtifacts=0, upload detections; =1, upload artifacts
params.plot3DScatter = 1;
params.useTheseFeatures = [3];

params.calculatePerformance = 0; % test algorithm performance against test set

params.runStatistics = 1;     % create box plot and run permutation and ranksum test

params.addAnnotations = 0;    % add annotations to portal or not?  0-no, 1-yes


try
  %% Load investigator specific information
  [dataKey, params, featFn] = f_setEnvironment(params);


  %% Establish IEEG Sessions
  if ~exist('session','var'),  session = [];  end  % load session if it does not exist
  session = f_openPortalSession(params, dataKey, session);


  %% Initial event detection 
  %  Perform initial event detection - calculate a simple feature using a
  %     sliding window and look for places where the feature crosses a
  %     threshold for a minimum amount of time
  if params.initialDetection
    fprintf('Running initial detections using: %s\n', params.feature);
    if ~params.runInParallel  % run in serial on one processor
      for r = 1: length(params.runThese)
        f_initialDetection(session.data(r), params, dataKey(params.runThese(r),:));
      end
    else                      % run in parallel on multiple processors
      try delete(gcp); 
      catch
      end
      parpool(params.maxParallelPools);
      parfor r = 1:length(params.runThese)
        parsession = IEEGSession(dataKey.portalId{params.runThese(r)},'jtmoyer','jtm_ieeglogin.bin');
        f_initialDetection(parsession.data, params, dataKey(params.runThese(r),:));
      end
    end
    try      % clear allData, because with new detections, it's out of date
      delete(fullfile(params.runDir, 'Output', [params.initialOutputLayer '-allData.mat']));
    catch
    end
    toc
  end


  %% Load/create allData 
  % Create allData, a structure that holds the channel numbers, start/stop
  %     times, and labels for annotations for all datasets in dataKey.
  %     Features for annotations are calculated below and added to allData.
%   if ~exist('allData', 'var')
%     try      % load file to save time
%       load(fullfile(params.runDir, 'Output', [params.initialOutputLayer '-allData.mat']));
%     catch    % download annotations from portal, overwrite clips file
%       allData = f_createAllData(dataKey, params);
%     end
%     toc
%   end

  
  %% Score detections
  % Create a test data set using the initial detections - this data set
  %   will include both events and artifacts.
  % Upload these test detections to the portal as a separate layer.

  if params.scoreDetections
    f_scoreDetections(session.data(r), layerName, allData(params.runThese(r)).timesUsec(these{params.runThese(r)},:), [1:4], 'testing', dataKey(params.runThese(r),:));
    % make vector indicating number of detections in each dataset
    % based on probability, randomly divide the desired number of detections between datasets
    % then run through each dataset and present the detections to be scored
    rng(1);  % seed random number generator
    
    for r = 1: length(allData)
      allLengths(r,1) = length(allData(r).channels);
    end
  %     sampleThese{r,:} = randperm(allLengths(r));
    sampleThese = sort(randsample(length(allLengths), numDetections, true, allLengths));
    numSamples = hist(sampleThese, 1:length(allLengths))';
    these = cell(length(allData),1);

    for r = 1: length(allData)
      if numSamples(r) > 0
        these{r} = sort(randi(allLengths(r), [numSamples(r), 1]));
  %       close all force;
  %       f_scoreDetections(session.data(r), layerName, allData(runThese(r)).timesUsec(these,:), [1:4], 'testing', dataKey(runThese(r),:));
  %       keyboard;
      end
    end

    for r = 1: length(params.runThese)
      if ~isempty(these{params.runThese(r)})
        close all force;
        keyboard;
      end
    end
  end

  %% clustering
  if params.artifactRemoval
    allData(r).features = f_calculateFeatures(allData(r), clips, featFn);
  % % plot histograms of 1/inter-crossings
  % bins = 0:15:300;
  % for i = 1:4
  %   subplot(2,2,i); bar(bins, allData(2).features{4,4}{i}); xlim ([-10 310]); xlabel('Fre quency (Hz)'); ylabel('Frequency Count'); title(sprintf('Channel %d',i));
  % end

    useData = allData; 

  %   useTheseFeatures = [1]; % which feature functions to use for clustering?
  %   useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params, runDir, 0.5);
  %   useData = f_removeAnnotations(session, useData, featFn, useTheseFeatures, 0);
  %   useTheseFeatures = [2]; % which feature functions to use for clustering?
  %   useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params, runDir, 0.5);
  %   useData = f_removeAnnotations(ses sion, useData, featFn, useTheseFeatures, 0);
    useData = f_unsupervisedClustering(session, useData, params.useTheseFeatures, params.runThese, params, runDir, 4.5);
    useData = f_removeAnnotations(session, useData, featFn, params.useTheseFeatures, 1);

    layerName = sprintf('%s-%s-%s', params.label, params.technique, 'just3-artifact');
    for r = 1:length(params.runThese)
      if params.addAnnotations 
        f_uploadAnnotations(session.data(r), layerName, useData(r).timesUsec, useData(r).channels, cellstr(repmat('Event',length(useData(r).timesUsec),1))); 
      end;  
    toc
    end
  end 



  if params.calculatePerformance
    scores = f_calculatePerformance(session, params.runThese, 'seizure-linelength-just3', 'testing')
    sensitivity = scores.truePositive / (scores.truePositive + scores.falseNegative)
    specificity = scores.trueNegative / (scores.falsePositive + scores.trueNegative)
    accuracy = (scores.truePositive + scores.trueNegative) / ...
      (scores.truePositive + scores.falseNegative + scores.falsePositive + scores.trueNegative)
  end

  %% Analyze results
  % if params.boxPlot
  %   perDay = 0;  % per day = 1 means break data into days; per day = 0 means plot per rat
  %   inputLayer = 'seizure-linelength';
  %   f_boxPlot(session, runDir, params.runThese, dataKey, 'seizure-linelength-output', inputLayer, perDay);
  %   fprintf('Box plot: %s-%s\n', params.label, params.technique);
  %   toc
  % end
  % 
  if params.runStatistics
    perDay = 0;  % per day = 1 means break data into days; per day = 0 means plot per rat
    inputLayer = 'seizure-linelength';
    pValues = f_statistics(session, params.runDir, params.runThese, dataKey, 'seizure-linelength-output', inputLayer, perDay);
  end

  toc;
  diary off;
catch err
  diary off;
  rethrow(err);
end
