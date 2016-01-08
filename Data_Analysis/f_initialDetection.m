function f_initialDetection(dataset, params, dataRow)
  %	Usage: f_initialDetection(dataset, params, dataRow);
  % Should be called by analyzeDataOnPortal.m
  %	
  %	f_initialDetection() will call f_initial_XXXX to perform event detection by
  % calculating a simple feature using a sliding window and then looking for
  % places where the feature crosses a threshold for a minimum amount of time
  %
  % XXXX = params.feature, something like 'linelength'
  % 
  % Note that f_initialDetections() contains supporting code for plotting and
  % saving data, while f_initial_XXXX does the actual sliding window and
  % feature calculation.  The idea is that f_initial_XXXX can be hacked
  % together while f_initialDetections() supports the feature development.
  % You can start and end at specific times in the file, this helps tune the
  % detector by finding sample detections and then seeing what a given
  % threshold/window duration will find.
  %
  % Input:
  %   dataset - single IEEG dataset
  %   params		-	a structure containing at least the following:
  %     params.startTime = '1:00:00:00'; % day:hour:minute:second, in portal time
  %     params.endTime = '1:01:00:00';   % day:hour:minute:second, in portal time
  %     params.minThresh = 2e2;       % minimum threshold for initial event detection
  %     params.minDur = 10;           % sec; minimum duration for detections
  %     params.viewInitialDetectionPlot = 1;  % view plot of feature overlaid on signal, 0/1
  %     params.function = @(x) (sum(abs(diff(x)))); % feature function
  %     params.windowLength = 2;         % sec, duration of sliding window
  %     params.windowDisplacement = 1;    % sec, amount to slide window
  %     params.blockDurMinutes = 15;      % minutes; amount of data to pull at once
  %     params.smoothDur = 20;   % sec; width of smoothing window
  %     params.maxThresh = params.minThresh*4;  
  %     params.maxDur = 120;    % sec; min duration of the seizures
  %     params.plotWidth = 1; % minutes, if plotting, how wide should the plot be?
  %   datarow - row from dataKey table corresponding to this dataset
  %
  % Output:
  %   to portal -> detections uploaded to portal as a layer called 'initial-XXXX'
  %   to file -> eg 'I023_A0001_D001-annot-initial-XXXX.txt - start/stop times of annots
  %
  % Jason Moyer 7/20/2015 
  % University of Pennsylvania Center for Neuroengineering and Therapeutics
  %
  % History:
  % 7/20/2015 - v1 - creation
  %.............

  leftovers = 0; % simple counter to find events that extend beyond the end of a block
  % for simplicty these events are just terminated at the end of the block

  % user specifies start/end time for analysis (in portal time), in form day:hour:minute:second
  % convert these times to usecs from start of file
  % remember that time 0 usec = 01:00:00:00
  timeValue = sscanf(params.startTime,'%d:');
  params.startUsecs = ((timeValue(1)-1)*24*60*60 + timeValue(2)*60*60 + ...
    timeValue(3)*60 + timeValue(4))*1e6; 
  if params.startUsecs <= 0  % day = 0 or 1:00:00:00
    params.startUsecs = round((datenum(dataRow.startEEG, 'dd-mmm-yyyy HH:MM:SS') ...
      - datenum(dataRow.startSystem, 'dd-mmm-yyyy HH:MM:SS'))*24*60*60*1e6);
  end
  timeValue = sscanf(params.endTime,'%d:');
  params.endUsecs = ((timeValue(1)-1)*24*60*60 + timeValue(2)*60*60 + ...
    timeValue(3)*60 + timeValue(4))*1e6; 
  % save time by only analyzing data that is relevant
%   dataset.snapName
%   dataset.channels(1).label
%   dataset.channels(1).get_tsdetails()
%   dataset.channels(1).get_tsdetails().getDuration
  if params.endUsecs <= 0 || params.endUsecs > dataset.rawChannels(1).get_tsdetails().getDuration % datenum(dataRow.endEEG)*24*60*60*1e6 
    params.endUsecs = round((datenum(dataRow.endEEG, 'dd-mmm-yyyy HH:MM:SS') ...
      - datenum(dataRow.startSystem, 'dd-mmm-yyyy HH:MM:SS'))*24*60*60*1e6);
  end
  
  % calculate number of blocks = # of times to pull data from portal
  % calculate number of windows = # of windows over which to calc feature
  fs = dataset.sampleRate;
  durationHrs = (params.endUsecs - params.startUsecs)/1e6/60/60;    % duration in hrs
  numBlocks = ceil(durationHrs/(params.blockDurMinutes/60));    % number of data blocks
  blockSize = params.blockDurMinutes * 60 * 1e6;        % size of block in usecs

  % save annotations out to a file so addAnnotations can upload them all at once
  annotFile = fullfile(params.runDir, 'Output', ...
    sprintf('%s-annot-initial-%s', dataset.snapName, params.feature));
  ftxt = fopen([annotFile '.txt'],'w');
  assert(ftxt > 0, 'Unable to open text file for writing: %s\n', [annotFile '.txt']);
  fclose(ftxt);  % this flushes the file
%   save([annotFile '.mat'],'params');

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
    
    % print out progress indicator every 50 blocks
    if mod(b, 50) == 1
      fprintf('%s: Processing data block %d of %d\n', dataset.snapName, b, numBlocks);
    end

    %%-----------------------------------------
    %%---  feature creation and data processing
    fh = str2func(sprintf('f_initial_%s', params.feature));
    output = fh(data,params,fs,curTime);
    %%---  feature creation and data processing
    %%-----------------------------------------
   
    % optional - plot data, width of plot set by user in params
    if params.viewInitialDetectionPlot 
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
%         pause;      % pause to view plot
       keyboard    % type return in command window to keep going, dbquit to stop
        clf;        % can change keyboard to pause to move more quickly
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
    % need to upload all annotations in a layer at once, but can't process
    % the whole file at once, so appending them to a file seems like the
    % best way to go. 
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
%   fprintf('%d leftover segments.\n', leftovers);
  
  % read annotations from file and upload to the portal
  if params.addAnnotations
    count = 0;
    successful = 0;
    while count < 10 && ~successful
      try
        f_addAnnotations(dataset, params); 
        successful = 1;
      catch
        count = count + 1;
        fprintf('Upload try #: %d\n', count);
      end
    end
    if ~successful
      error('Unable to upload data.');
    end
  end;
end
