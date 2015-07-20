function f_eventDetection(dataset, params, runDir, dataRow)
  % Usage: f_feature_energy(dataset, params)
  % Input: 
  %   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
  %   'params'    -   Structure containing parameters for the analysis
  % 
%   dbstop in f_eventDetection at 10
  
  leftovers = 0; % simple counter to find events that are extend beyond the end of a block
  % for simplicty these events are just terminated at the end of the block

  % user specifies start/end time for analysis (in portal time), in form day:hour:minute:second
  % convert these times to usecs from start of file
  % remember that time 0 usec = 01:00:00:00
  timeValue = sscanf(params.startTime,'%d:');
  params.startUsecs = ((timeValue(1)-1)*24*60*60 + timeValue(2)*60*60 + ...
    timeValue(3)*60 + timeValue(4))*1e6; 
  if params.startUsecs <= 0  % day = 0 or 1:00:00:00
    params.startUsecs = round((datenum(dataRow.startEEG, 'dd-mmm-yyyy HH:MM:SS') - datenum(dataRow.startSystem, 'dd-mmm-yyyy HH:MM:SS'))*24*60*60*1e6);
  end
  timeValue = sscanf(params.endTime,'%d:');
  params.endUsecs = ((timeValue(1)-1)*24*60*60 + timeValue(2)*60*60 + ...
    timeValue(3)*60 + timeValue(4))*1e6; 
  % save time by only analyzing data that is relevant
  if params.endUsecs <= 0 || params.endUsecs > dataset.channels(1).get_tsdetails().getDuration
    params.endUsecs = round((datenum(dataRow.endEEG, 'dd-mmm-yyyy HH:MM:SS') - datenum(dataRow.startSystem, 'dd-mmm-yyyy HH:MM:SS'))*24*60*60*1e6);
  end
  
  % calculate number of blocks = # of times to pull data from portal
  % calculate number of windows = # of windows over which to calc feature
  fs = dataset.sampleRate;
  durationHrs = (params.endUsecs - params.startUsecs)/1e6/60/60;    % duration in hrs
  numBlocks = ceil(durationHrs/(params.blockDurMinutes/60));    % number of data blocks
  blockSize = params.blockDurMinutes * 60 * 1e6;        % size of block in usecs

  % save annotations out to a file so addAnnotations can upload them all at once
  annotFile = fullfile(runDir, sprintf('/Output/%s-annot-%s-%s',dataset.snapName,params.label,params.technique));
  ftxt = fopen([annotFile '.txt'],'w');
  assert(ftxt > 0, 'Unable to open text file for writing: %s\n', [annotFile '.txt']);
  fclose(ftxt);  % this flushes the file
  save([annotFile '.mat'],'params');

  % if saving feature calculations to a text file, open and clear file
  if params.saveToDisk
    featureFile = fullfile(runDir, sprintf('./Output/%s-feature-%s-%s',dataset.snapName,params.label,params.technique));
    ftxt = fopen([featureFile '.txt'],'w');
    assert(ftxt > 0, 'Unable to open text file for writing: %s\n', [featureFile '.txt']);
    fclose(ftxt);  % this flushes the file
  end

  % for each block (block size is set by user in parameters)
  for b = 1: numBlocks
    curTime = params.startUsecs + (b-1)*blockSize;
    
    % get data - sometimes it takes a few tries for portal to respond
    count = 0;
    successful = 0;
    while count < 10 && ~successful
      try
        data = dataset.getvalues(curTime, blockSize, params.channels);
        successful = 1;
      catch
        count = count + 1;
        fprintf('Try #: %d\n', count);
      end
    end
    if ~successful
      error('Unable to get data.');
    end
    
    fprintf('%s: Processing data block %d of %d\n', dataset.snapName, b, numBlocks);

    %%-----------------------------------------
    %%---  feature creation and data processing
    fh = str2func(sprintf('f_%s_%s', params.label, params.technique));
    output = fh(data,params,fs,curTime);
    %%---  feature creation and data processing
    %%-----------------------------------------
   
    % save feature calculation to file (optional)
    if params.saveToDisk
      try
        ftxt = fopen([featureFile '.txt'],'a');  % append rather than overwrite
        assert(ftxt > 0, 'Unable to open text file for appending: %s\n', [featureFile '.txt']);
        fwrite(ftxt,output,'single');
        fclose(ftxt);  
      catch err
        fclose(ftxt);
        rethrow(err);
      end
    end
    
    % optional - plot data, width of plot set by user in params
    if params.viewData 
      plotWidth = params.plotWidth*60*1e6; % usecs to plot at a time
      numPlots = blockSize/plotWidth;
      time = 1: length(data);
      time = time/fs*1e6 + curTime;
      
      p = 1;
      while (p <= numPlots)
        % remember portal time 0 = 01:00:00:00
        day = floor(output(1,1)/1e6/60/60/24) + 1;
        leftTime = output(1,1) - (day-1)*24*60*60*1e6;
        hour = floor(leftTime/1e6/60/60);
        leftTime = (day-1)*24*60*60*1e6 + hour*60*60*1e6;
        startPlot = (p-1) * plotWidth + curTime;
        endPlot = min([startPlot + plotWidth   time(end)]);
        dataIdx = find(startPlot <= time & time <= endPlot);
        ftIdx = find(startPlot <= output(:,1) & output(:,1) <= endPlot);
        for c = 1: length(params.channels)
          figure(1); subplot(2,2,c); hold on;
          plot((time(dataIdx)-leftTime)/1e6/60, data(dataIdx,c)/max(data(dataIdx,c)), 'Color', [0.5 0.5 0.5]);
          plot((output(ftIdx,1)-leftTime)/1e6/60, output(ftIdx,c+1)/max(output(ftIdx,c+1)),'k');
          axis tight;
          xlabel(sprintf('(minutes) Day %d, Hour %d',day,hour));
          title(sprintf('Channel %d',c));
          line([(startPlot-leftTime)/1e6/60 (endPlot-leftTime)/1e6/60],[params.minThresh/max(output(ftIdx,c+1)) params.minThresh/max(output(ftIdx,c+1))],'Color','r');
          line([(startPlot-leftTime)/1e6/60 (endPlot-leftTime)/1e6/60],[params.maxThresh/max(output(ftIdx,c+1)) params.maxThresh/max(output(ftIdx,c+1))],'Color','b');
          hold off;
        end
        
        p = p + 1;
        keyboard;
 
%         % plots of signal data, a la portal       
%         figure(2); hold on;
%         for c = 1: 4
%           plot((time(dataIdx)-leftTime)/1e6/60, c+data(dataIdx,c)/max(data(dataIdx,c)), 'Color', [0.5 0.5 0.5]);          
%         end
        
       clf;
      end
    end

    % find elements of output that are over threshold and convert to
    % start/stop time pairs (in usec)
    annotChannels = [];
    annotUsec = [];
    % end time is one window off b/c of diff - add row of zeros to start
%     [idx, chan] = find([zeros(1,length(params.channels)+1); diff((output > params.minThresh))]);
    [idx, chan] = find(diff([zeros(1,length(params.channels)+1);...
      (output >= params.minThresh) .* (output < params.maxThresh) ]));
    if sum(chan == 0) > 0
      keyboard;
    end
    i = 1;
    while i <= length(idx)-1
      if (chan(i+1) == chan(i))
        if ( (output(idx(i+1),1) - output(idx(i),1)) >= params.minDur*1e6  ...
            && (output(idx(i+1),1) - output(idx(i),1)) < params.maxDur*1e6)
          annotChannels = [annotChannels; chan(i)];
          annotUsec = [ annotUsec; [output(idx(i),1) output(idx(i+1),1)] ];
        end
        i = i + 2;
      else % annotation has a beginning but not an end
        % force the annotation to end at the end of the block
        leftovers = leftovers + 1;  % just to get of a sense of how many leftovers there are
        if ( (curTime + blockSize) - output(idx(i),1) >= params.minDur*1e6 ) % require min duration?
          annotChannels = [annotChannels; chan(i)];
          annotUsec = [ annotUsec; [output(idx(i),1)  curTime+blockSize] ];
        end
        i = i + 1;
      end
    end
    % output needs to be in 3xX matrix, first row is channels
    annotOutput = [annotChannels-1 annotUsec]';
    
    % append annotations to output file
    if ~isempty(annotOutput)
      try
        ftxt = fopen([annotFile '.txt'],'a'); % append rather than overwrite
        assert(ftxt > 0, 'Unable to open text file for appending: %s\n', [annotFile '.txt']);
        fwrite(ftxt,annotOutput,'single');
        fclose(ftxt);
      catch err
        fclose(ftxt);
        rethrow(err);
      end
    end
  end
  fprintf('%d leftover segments.\n', leftovers);
end
