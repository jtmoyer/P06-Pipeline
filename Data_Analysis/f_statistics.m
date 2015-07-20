function pValues = f_statistics(session, runDir, runThese, dataKey, layerName, inputLayer, perDay)
  % f_boxPlot will create a box and whisker plot for each data session in
  %    runThese. Plots are grouped by dataKey.treatmentGroup.
  %
  % Inputs
  % session: IEEG session including all sessions for which to plot events
  % runThese: vector of indexes to plot (cooresponding to dataKey.index)
  % dataKey: table of index, animalId, portalId, treatmentGroup
  % layerName: annotation layer for which to plot events
  %
%   dbstop in f_statistics at 66;
  
  groupName = cell(length(runThese),1);
  lengthInDays = nan(length(runThese),1);
  eventsPerDay = cell(length(runThese),1);
%   artifactsPerDay = cell(length(runThese),1);
%   numTrials = 1000;

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
      if perDay 
        eventsPerDay{r} = histc(timesUsec(:,1), dayBinsUsec);
        % drop the last bin (zero)
        eventsPerDay{r}(end) = [];
      else
        eventsPerDay{r} = length(timesUsec(:,1));
      end
    end
  end
    
%   % create column vectors of data
%   eventsPerDayCol = [];
%   groupsPerDayCol = [];
%   for r = 1:size(eventsPerDay,1)
%     eventsPerDayCol = [eventsPerDayCol; eventsPerDay{r}(:)];
%     groupsPerDayCol = [groupsPerDayCol; repmat(groupName(r), size(eventsPerDay{r}(:)))];
%   end
  uniqueGroups = unique(groupName(~cellfun(@isempty, groupName)));
  groupCombos = nchoosek(1:length(uniqueGroups),2);
  
  pValues = cell(size(groupCombos,1), 3);
  for g = 1: size(groupCombos,1)
    firstGroup = eventsPerDay(strcmp(groupName, uniqueGroups(groupCombos(g,1))));
    secondGroup = eventsPerDay(strcmp(groupName, uniqueGroups(groupCombos(g,2))));
    groupsCombined = [firstGroup; secondGroup];
    permutations = nchoosek(1:length(groupsCombined),length(firstGroup));
    
%     idx1 = strcmp(g, uniqueGroups(groupCombos(g,1)));
%     idx2 = strcmp(groupsPerDayCol, uniqueGroups(groupCombos(g,2)));
%     groupData = [[eventsPerDayCol(idx1) repmat(groupCombos(g,1), sum(idx1), 1)]; ...
%       [eventsPerDayCol(idx2) repmat(groupCombos(g,2), sum(idx2), 1)]];
%     [~, ~, ~, tSTATS] = ttest2(groupData(groupData(:,2) == groupCombos(g,1)), groupData(groupData(:,2) == groupCombos(g,2)));
%     tValues(1) = tSTATS.tstat;  % tValues(1) is the t-value for the real data
%     permutations = randi(2, [length(groupData) numTrials]);
    
    tValues = nan(size(permutations,1),1);
    for n = 1: size(permutations,1)
      groupA = vertcat(groupsCombined{ismember(1:length(groupsCombined),permutations(n,:))});
      groupB = vertcat(groupsCombined{~ismember(1:length(groupsCombined),permutations(n,:))});
%       [~, ~, ~, tSTATS] = ttest2(groupA, groupB);
%       tValues(n) = tSTATS.tstat;  % tValues(1) is t value of actual data
      [~, ~, rSTATS] = ranksum(groupA, groupB);
      tValues(n) = rSTATS.ranksum;  % tValues(1) is t value of actual data
    end
    
    pValues{g,1} = uniqueGroups{groupCombos(g,1)};
    pValues{g,2} = uniqueGroups{groupCombos(g,2)};
    if tValues(1) < mean(tValues)
      pValues{g,3} = sum(tValues < tValues(1)) / length(tValues);
    else 
      pValues{g,3} = sum(tValues > tValues(1)) / length(tValues);
    end
    
    [counts, centers] = hist(tValues(2:end),10);
    h = figure(1);
    bar(centers,counts);
    line([tValues(1) tValues(1)], [0 max(counts)], 'Color', 'r');
    ylabel('Count');
    xlabel('tValues');
    title([uniqueGroups{groupCombos(g,1)} ' vs ' uniqueGroups{groupCombos(g,2)}]);
    legend('Shuffled', 'Actual', 'Location', 'NorthWest');
    print(h, fullfile(runDir, 'output', 'Figures', [uniqueGroups{groupCombos(g,1)} '_' uniqueGroups{groupCombos(g,2)} '_pvalue.png']), '-dpng');
  end
  
  %   % create column vectors of data
%   eventsPerDayCol = [];
%   groupsPerDayCol = [];
%   for r = 1:size(eventsPerDay,1)
%     eventsPerDayCol = [eventsPerDayCol; eventsPerDay{r}(:)];
%     groupsPerDayCol = [groupsPerDayCol; repmat(groupName(r), size(eventsPerDay{r}(:)))];
%   end
%   uniqueGroups = unique(groupsPerDayCol);
%   groupCombos = nchoosek(1:length(uniqueGroups),2);
%   
%   tValues = nan(numTrials+1, 1);
%   pValues = cell(size(groupCombos,1), 3);
%   for g = 1: size(groupCombos,1)
%     idx1 = strcmp(g, uniqueGroups(groupCombos(g,1)));
%     idx2 = strcmp(groupsPerDayCol, uniqueGroups(groupCombos(g,2)));
%     groupData = [[eventsPerDayCol(idx1) repmat(groupCombos(g,1), sum(idx1), 1)]; ...
%       [eventsPerDayCol(idx2) repmat(groupCombos(g,2), sum(idx2), 1)]];
%     [~, ~, ~, tSTATS] = ttest2(groupData(groupData(:,2) == groupCombos(g,1)), groupData(groupData(:,2) == groupCombos(g,2)));
%     tValues(1) = tSTATS.tstat;  % tValues(1) is the t-value for the real data
%     permutations = randi(2, [length(groupData) numTrials]);
%     
%     for n = 1: numTrials
% %       a = groupData(permutations(:,n) == 1);
% %       b = groupData(permutations(:,n) == 2);
% %       [~, ~, ~, testSTATS] = ttest2(a,b)
%       [~, ~, ~, tSTATS] = ttest2(groupData(permutations(:,n) == 1), groupData(permutations(:,n) == 2));
%       tValues(n+1) = tSTATS.tstat;
%     end
%     
%     pValues{g,1} = uniqueGroups{groupCombos(g,1)};
%     pValues{g,2} = uniqueGroups{groupCombos(g,2)};
%     if tValues(1) < mean(tValues)
%       pValues{g,3} = sum(tValues < tValues(1)) / length(tValues);
%     else 
%       pValues{g,3} = sum(tValues > tValues(1)) / length(tValues);
%     end
%     
%     [counts, centers] = hist(tValues(2:end),10);
%     h = figure(1);
%     bar(centers,counts);
%     line([tValues(1) tValues(1)], [0 max(counts)], 'Color', 'r');
%     ylabel('Count');
%     xlabel('tValues');
%     title([uniqueGroups{groupCombos(g,1)} ' vs ' uniqueGroups{groupCombos(g,2)}]);
%     legend('Shuffled', 'Actual', 'Location', 'NorthWest');
%     print(h, fullfile(runDir, 'output', 'Figures', [uniqueGroups{groupCombos(g,1)} '_' uniqueGroups{groupCombos(g,2)} '_pvalue.png']), '-dpng');
%   end
end