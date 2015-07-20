function f_boxPlotPerDay(session, runDir, runThese, dataKey, layerName)
  % f_boxPlot will create a box and whisker plot for each data session in
  %    runThese. Plots are grouped by dataKey.treatmentGroup.
  %
  % Inputs
  % session: IEEG session including all sessions for which to plot events
  % runThese: vector of indexes to plot (cooresponding to dataKey.index)
  % dataKey: table of index, animalId, portalId, treatmentGroup
  % layerName: annotation layer for which to plot events
  %
%   dbstop in f_boxPlotPerDay at 86
  
  groupName = cell(length(runThese),1);
  lengthInDays = nan(length(runThese),1);
  eventsPerDay = cell(length(runThese),1);

  % calculate length of recording, get number of events, bin events per day
  for r = 1: length(runThese)
    % find appropriate annLayer based on layerName
    assert(strcmp(session.data(r).snapName, dataKey.portalId(runThese(r))), 'SnapName does not match dataKey.portalID\n');
    fname = fullfile(runDir, sprintf('./Output/%s-annot-%s.mat',session.data(r).snapName,layerName));
    try
      load(fname);
    catch
      fprintf('File not found: %s; downloading data from portal\n',fname);
      [~, timesUsec, ~] = f_getAllAnnots(session.data(r), layerName);%, params);
      if ~isempty(timesUsec)
        save(fname, 'timesUsec', 'eventChannels');
      end
    end

    if ~isempty(timesUsec)
      % use histcounts to calculate number of events per day
      groupName{r} = dataKey.treatmentGroup{runThese(r)};
      startUsec = datenum(dataKey.startEEG(runThese(r)), 'dd-mmm-yyyy HH:MM:SS')*24*60*60*1e6 ...
        - datenum(dataKey.startSystem(runThese(r)), 'dd-mmm-yyyy HH:MM:SS')*24*60*60*1e6;
      endUsec = datenum(dataKey.endEEG(runThese(r)), 'dd-mmm-yyyy HH:MM:SS')*24*60*60*1e6 ...
        - datenum(dataKey.startSystem(runThese(r)), 'dd-mmm-yyyy HH:MM:SS')*24*60*60*1e6;
      lengthInDays(r) = datenum(dataKey.endEEG(runThese(r)), 'dd-mmm-yyyy HH:MM:SS') ...
        - datenum(dataKey.startEEG(runThese(r)), 'dd-mmm-yyyy HH:MM:SS');
      dayBinsUsec = startUsec: 24*60*60*1e6: endUsec;
      eventsPerDay{r} = histc(timesUsec(:,1), dayBinsUsec);
      % drop the last bin (zero)
      eventsPerDay{r}(end) = [];
    end
  end
    
  % create box plot
  eventsPerDayCol = [];
  groupsPerDayCol = [];
  for r = 1:size(eventsPerDay,1)
    eventsPerDayCol = [eventsPerDayCol; eventsPerDay{r}(:)];
    groupsPerDayCol = [groupsPerDayCol; repmat(groupName(r), size(eventsPerDay{r}(:)))];
  end
  uniqueGroups = unique(groupsPerDayCol);
  figure(1); h = boxplot(eventsPerDayCol, groupsPerDayCol, 'groupOrder', uniqueGroups); hold on;
  xlabel('Treatment Group');
  ylabel('Postulated Epileptiform Events per Day');
  title(layerName);

  % overlay data points on top of box plot
  for r = 1: length(uniqueGroups)
    inds = cellfun(@strcmp, groupsPerDayCol, cellstr(repmat(uniqueGroups{r}, size(groupsPerDayCol))));
    plot(repmat(r, size(inds(inds==1))), eventsPerDayCol(inds), 'o', 'MarkerSize', 6);
  end
  
%   % look at distribution - is it gaussian?
%   figure(2); 
%   for r = 1: length(uniqueGroups)
%     subplot(length(uniqueGroups),1,r);
%     inds = cellfun(@strcmp, groupsPerDayCol, cellstr(repmat(uniqueGroups{r}, size(groupsPerDayCol))));
%     y = hist(eventsPerDayCol(inds),20);
%     bar(y);
%     title(uniqueGroups{r});
%   end
  
  % perform ranksum test, use sigstar to plot significance levels
  figure(1);
  sigcell = {};
  sigprob = [];
  for r = 1: length(uniqueGroups)
    inds = cellfun(@strcmp, groupsPerDayCol, cellstr(repmat(uniqueGroups{r}, size(groupsPerDayCol))));
%     fprintf('\nGroup: %s   Total number of days recorded: %d\n', uniqueGroups{r}, length(find(inds)));
    for j = r+1: length(uniqueGroups)
      inds2 = cellfun(@strcmp, groupsPerDayCol, cellstr(repmat(uniqueGroups{j}, size(groupsPerDayCol))));
      [p(r,j) h0(r,j)] = ranksum(eventsPerDayCol(inds), eventsPerDayCol(inds2));
      fprintf('\nTest %s vs %s, p = %0.3f, h = %d\n', uniqueGroups{r}, uniqueGroups{j}, p(r,j), h0(r,j));
      sigcell = [sigcell, [r j]];
      sigprob = [sigprob p(r,j)];
    end
  end
  sigstar(sigcell, sigprob);
  ylim([0 400]);

  
  % plot rats individually to get a sense where the data points are
  colors = ['k' 'b' 'r' 'g'];
  figure(3); hold on;
  for r = 1:size(eventsPerDay,1)
    animalNumber = str2num(session.data(r).snapName(9:10));
    c = strcmp(uniqueGroups, groupName{r});
    h2(c) = plot(repmat(animalNumber, size(eventsPerDay{r})), eventsPerDay{r}, 'Marker', '.', 'Color', colors(c));
  end
  legend(h2, uniqueGroups{1:4});  
  title(layerName);
  ylim([0 400]);
end