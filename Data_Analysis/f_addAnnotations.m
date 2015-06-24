function f_addAnnotations(dataset, params, runDir)
  %	Usage: f_addAnnotations(dataset, params);
  %	
  %	dataset		-	IEEGDataset object
  %	params		-	string label for events
  %
  %	Function will upload to the IEEG portal the given events obtained from running various detection
  %	algorithms (e.g. spike_AR.m). Annotations will be associated with eventChannels and given a label.
  %
%   dbstop in f_addAnnotations at 15

  % read in annotations from text file
  % annotations must be in the form [channels timeStartUSecs timeEndUSecs]
  % which is a Xx3 matrix, one start/stop time pair to one channel
  fname = fullfile(runDir, sprintf('./Output/%s-annot-%s-%s.txt',dataset.snapName,params.label,params.technique));
  try
    fileExist = dir(fname);
    if fileExist.bytes > 0
      m = memmapfile(fname,'Format','single');
    else
      fprintf('No data found in: %s\n',fname);
      return;
    end
  catch
    fprintf('File not found: %s\n',fname);
    return;
  end

  % data is in 3xX format, first row is channels; convert to columns
  eventData = reshape(m.data,3,[]);
  eventChannels = eventData(1,:)';
  eventTimesUsec = eventData(2:3,:)';

  % want to combine overlapping annotations for feature analysis.
  % if end time of first row is later than start time of second row,
  % there is an overlap - change end time of both to max end time of both
  % keep running through data until no more changes are found.
  [~,idx] = sort(eventTimesUsec(:,1));
  times = eventTimesUsec(idx,:);
  chans = eventChannels(idx);

  somethingChanged = 1;
  while somethingChanged
    somethingChanged = 0;
    i = 2;
    while i <= length(chans)
      if (times(i-1,2) > times(i,1)) && (times(i-1,2) ~= times(i,2))
        times(i-1,2) = max([times(i-1,2) times(i,2)]);
        times(i,2) = max([times(i-1,2) times(i,2)]);
        somethingChanged = 1;
      end
      i = i + 1;
    end
  end

  % if the end times match between rows, change the start times to the
  % earliest start time.  keep running until no more changes found.
  somethingChanged = 1;
  while somethingChanged
    somethingChanged = 0;
    i = 2;
    while i <= length(chans)
      if (times(i,1) > times(i-1,1)) && (times(i-1,2) == times(i,2))
        times(i,1) = times(i-1,1);
        somethingChanged = 1;
      end
      i = i + 1;
    end
  end

  % there might be multiple annotations with same start/stop time on the
  % same channel (from having several annots in same region)
  [~,idx] = sort(chans);
  times = times(idx,:);
  chans = chans(idx);
  i = length(chans);
  while i > 1
    if chans(i) == chans(i-1)
      if int64(times(i,1)) == int64(times(i-1,1)) && int64(times(i,2)) == int64(times(i-1,2))
        chans(i) = [];
        times(i,:) = [];
      end
    end
    i = i - 1;
  end
  
  % run from end to beginning of annotations - if start and end times
  % match, compress into one annotation across multiple channels
  [~,idx] = sort(times(:,1));
  times = times(idx,:);
  chans = num2cell(chans(idx));
  i = length(chans);
  while i > 1
    if int64(times(i,1)) == int64(times(i-1,1)) && int64(times(i,2)) == int64(times(i-1,2))
      chans{i-1} = [chans{i-1} chans{i}];
      chans(i) = [];
      times(i,:) = [];
    end
    i = i - 1;
  end
  eventChannels = chans;
  eventTimesUsec = times;

  % remove existing annotation layer
  layerName = sprintf('%s-%s',params.label,params.technique);
  try 
    fprintf('\nRemoving existing layer\n');
    dataset.removeAnnLayer(layerName);
  catch 
    fprintf('No existing layer\n');
  end
  
  % create new layer, figure out how many unique channels there are
  annLayer = dataset.addAnnLayer(layerName);
%   uniqueAnnotChannels = unique([eventChannels{:}]);
  ann = cell(length(eventChannels),1);
  fprintf('Creating annotations...\n');

  % create annotations one channel at a time
  for i = 1:numel(eventChannels)
    ann{i} = IEEGAnnotation.createAnnotations(eventTimesUsec(i,1), eventTimesUsec(i,2), 'Event', params.label, dataset.channels(eventChannels{i}));
%     ann = [ann IEEGAnnotation.createAnnotations(eventTimesUsec(i,1), eventTimesUsec(i,2), 'Event', params.label, dataset.channels(i))];
%     tmpChan = uniqueAnnotChannels(i);
%     ann = [ann IEEGAnnotation.createAnnotations(eventTimesUsec(eventChannels==tmpChan,1), eventTimesUsec(eventChannels==tmpChan,2),'Event', params.label,dataset.channels(tmpChan))];
  end
  fprintf('done!\n');

  % upload annotations 5000 at a time (freezes if adding too many)
  numAnnot = numel(ann);
  startIdx = 1;
  fprintf('Adding annotations...\n');
  for i = 1:ceil(numAnnot/5000)
    fprintf('Adding %d to %d\n',startIdx,min(startIdx+5000,numAnnot));
    annLayer.add([ann{startIdx:min(startIdx+5000,numAnnot)}]);
    startIdx = startIdx+5000;
  end
  fprintf('done!\n');
end
