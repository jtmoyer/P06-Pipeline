function allData = f_createAllData(dataKey, params)
  %	Usage: outData = f_createAllData(dataset, params);
  % Called by analyzeDataOnPortal.m
  %	
  % f_createAllData() will download annotations from the initialOutputLayer
  %   and save the channel number, start/stop times, and labels to allData
  %   structure.  It will also save the data clips to file for faster
  %   retrieval when calculating features later in the pipeline.  Any
  %   existing data clips files will be overwritten, with the assumption
  %   that allData.m is missing and therefore initial detections have changed.
  %
  % Input:
  %   dataKey   -  a table with subject index, portal ID, and other info
  %   params    - a structure containing at least the following:
  %     params.initialOutputLayer - the layer with the initial detections
  %     params.runDir - % investigator specific directory, see
  %       f_setEnvironment()
  %
  % Output:
  %   allData   - a structure containing channel numbers, start/stop times,
  %     and labels for all annotations for all animals in dataKey
  %
  % Jason Moyer 7/20/2015 
  % University of Pennsylvania Center for Neuroengineering and Therapeutics
  %
  % History:
  % 7/20/2015 - v1 - creation
  %.............

  % initialize allData
  len = size(dataKey, 1);
  allData = struct('index', dataKey.portalId, 'channels', cell(len,1), ...
    'timesUsec', cell(len,1), 'labels', cell(len,1), 'features', cell(len,1));

%   % create new IEEG session with ALL datasets in dataKey loaded
%   try delete(gcp); 
%   catch
%   end
%   parpool(params.maxParallelPools);
% 
%   parfor r = 1: size(dataKey, 1)
%     warning('off');
%     session = IEEGSession(dataKey.portalId{r},'jtmoyer','jtm_ieeglogin.bin');
%     warning('on');
% 
%     clipsFile = fullfile(params.runDir, 'Output', ...
%       sprintf('%s-clips-%s.txt',session.data(1).snapName, params.initialOutputLayer));
% 
%     % for each dataset in dataKey, download data, save channels, times,
%     %   labels to allData structure.  
%     try
%       [allEvents, timesUsec, channels] = f_getAllAnnots(session.data(1), params.initialOutputLayer);
%       labels = {allEvents.description}';
%       allData(r).channels = channels;
%       allData(r).timesUsec = timesUsec;
%       allData(r).labels = labels;
% 
%       % download data clips and save them to clipsFile.  Download all
%       %   channels, rather than just the channels with detections, since some
%       %   features may need data from all channels (like correlation).
%       fprintf('%s: Downloading data clips from portal...\n', session.data(1).snapName);
%       clips = cell(size(timesUsec,1),1);
%       numChans = length(session.data(1).channels);
%       for i = 1:size(allEvents,2)
%         count = 0;    % get data - sometimes it takes a few tries for portal to respond
%         successful = 0;
%         while count < 10 && ~successful
%           try
%             tmpDat = session.data(1).getvalues(timesUsec(i,1), timesUsec(i,2)-timesUsec(i,1), 1:numChans);
%             successful = 1;
%           catch
%             count = count + 1;
%             fprintf('Try #: %d\n', count);
%           end
%         end
%         if ~successful
%           error('Unable to get data.');
%         end
%         tmpDat(isnan(tmpDat)) = 0;
%         clips{i} = tmpDat;
%       end
%       clips = clips(~cellfun('isempty', clips)); 
%       save(clipsFile, 'clips', 'timesUsec', 'channels', 'labels', '-v7.3');
%     catch err
%       rethrow(err);
%       fprintf('%s: layer %s does not exist.\n', session.data(1).snapName, params.initialOutputLayer);
%     end
%   end
%   % save allData to allData.mat file
%   save(fullfile(params.runDir, 'Output', [params.initialOutputLayer '-allData.mat']), 'allData');
% end  
  
  % initialize allData
  len = size(dataKey, 1);
  allData = struct('index', dataKey.portalId, 'channels', cell(len,1), ...
    'timesUsec', cell(len,1), 'labels', cell(len,1), 'features', cell(len,1));

  % create new IEEG session with ALL datasets in dataKey loaded
  warning('off');
  session = IEEGSession(dataKey.portalId{1},'jtmoyer','jtm_ieeglogin.bin');
  for r = 2: size(dataKey, 1)
    session.openDataSet(dataKey.portalId{r});
  end
  warning('on');
  
  for r = 1: size(dataKey, 1)
    clipsFile = fullfile(params.runDir, 'Output', ...
      sprintf('%s-clips-%s.txt',session.data(r).snapName, params.initialOutputLayer));

    % for each dataset in dataKey, download data, save channels, times,
    %   labels to allData structure.  
    try
      [allEvents, timesUsec, channels] = f_getAllAnnots(session.data(r), params.initialOutputLayer);
      labels = {allEvents.description}';
      allData(r).channels = channels;
      allData(r).timesUsec = timesUsec;
      allData(r).labels = labels;

      % download data clips and save them to clipsFile.  Download all
      %   channels, rather than just the channels with detections, since some
      %   features may need data from all channels (like correlation).
      fprintf('%s: Downloading data clips from portal...\n', session.data(r).snapName);
      clips = cell(size(timesUsec,1),1);
      numChans = length(session.data(r).channels);
      for i = 1:size(allEvents,2)
        count = 0;    % get data - sometimes it takes a few tries for portal to respond
        successful = 0;
        while count < 10 && ~successful
          try
            tmpDat = session.data(r).getvalues(timesUsec(i,1), timesUsec(i,2)-timesUsec(i,1), 1:numChans);
            successful = 1;
          catch
            count = count + 1;
            fprintf('Try #: %d\n', count);
          end
        end
        if ~successful
          error('Unable to get data.');
        end
        tmpDat(isnan(tmpDat)) = 0;
        clips{i} = tmpDat;
      end
      clips = clips(~cellfun('isempty', clips)); 
      save(clipsFile, 'clips', 'timesUsec', 'channels', 'labels', '-v7.3');
    catch
      fprintf('%s: layer %s does not exist.\n', session.data(r).snapName, layerName);
    end
  end
  % save allData to allData.mat file
  save(fullfile(params.runDir, 'Output', [params.initialOutputLayer '-allData.mat']), 'allData');
end