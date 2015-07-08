function [channels, clips, timesUsec, labels] = f_loadDataClips(dataset, params, runDir)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_loadDataClips at 18
    
  % download data from portal or load from file
  channels = [];
  clips = [];
  timesUsec = [];
  labels = [];
  params.startUsecs = 0;
  fs = dataset.sampleRate;
  clipsFile =  fullfile(runDir, sprintf('/Output/%s-clips-%s-%s.mat',dataset.snapName,params.label,params.technique));
  if ~exist(clipsFile, 'file')
    layerName = sprintf('%s-%s', params.label, params.technique);
    try
      [allEvents, timesUsec, channels] = f_getAllAnnots(dataset, layerName);
      labels = {allEvents.description}';
      fprintf('%s: Downloading data clips from portal...\n', dataset.snapName);
    
      % save data clips to file for fast retrieval
      clips = cell(size(timesUsec,1),1);
      numChans = length(dataset.channels);
      for i = 1:size(allEvents,2)
        count = 0;    % get data - sometimes it takes a few tries for portal to respond
        successful = 0;
        while count < 10 && ~successful
          try
            tmpDat = dataset.getvalues(timesUsec(i,1), timesUsec(i,2)-timesUsec(i,1), 1:numChans);
            successful = 1;
          catch
            count = count + 1;
            fprintf('Try #: %d\n', count);
          end
        end
        if ~successful
          error('Unable to get data.');
        end
        tmpDat(isnan(tmpDat)) = 0;   % tmpDat = dataset.getvalues(timesUsec(i,1), timesUsec(i,2)-timesUsec(i,1), channels);
        clips{i} = tmpDat;
      end
      clips = clips(~cellfun('isempty', clips)); 
      save(clipsFile, 'clips', 'timesUsec', 'channels', 'labels', '-v7.3');
    catch
      fprintf('%s: layer %s does not exist.\n', dataset.snapName, layerName);
      channels = [];
      clips = {};
      timesUsec = [];
    end
  else
    fprintf('%s: Loading data clips from file...\n', dataset.snapName);
    load(clipsFile);
  end
end