function f_plot1DFeatures(dataset, thisData, funcInds, featureClasses)
%   dbstop in f_plot1Dfeatures at 21

  colors = ['r' 'b' 'g' 'y' 'm' 'c' 'k'];
  fs = dataset.sampleRate;
  figure(2);
  
  idx = find(featureClasses);
  for i = 1: length(idx)
    data = dataset.getvalues(thisData.timesUsec(idx(i),1), thisData.timesUsec(idx(i),2)-thisData.timesUsec(idx(i),1), 1:length(dataset.channels));
    t = (1:size(data,1))/fs;
    for c = 1: length(thisData.channels{idx(i)})
      day = floor(thisData.timesUsec(idx(i),1)/1e6/60/60/24) + 1;
      leftTime = thisData.timesUsec(idx(i),1) - (day-1)*24*60*60*1e6;
      hour = floor(leftTime/1e6/60/60);
      leftTime = thisData.timesUsec(idx(i),1) - (day-1)*24*60*60*1e6 - hour*60*60*1e6;
      minute = floor(leftTime/1e6/60);
      leftTime = thisData.timesUsec(idx(i),1) - (day-1)*24*60*60*1e6 - hour*60*60*1e6 - minute*60*1e6;
      second = floor(leftTime/1e6);

      subplot(4,1,thisData.channels{idx(i)}(c)); 
      plot(t, data(:,thisData.channels{idx(i)}(c)));
      title(sprintf('Artifact in %s: %02d:%02d:%02d:%02d Feat %d=%0.2f', dataset.snapName, day, hour, minute, second, funcInds, thisData.features{idx(i), funcInds}(c)));
    end
    pause; clf;
  end
  
  
%   featureNumbers = repmat(funcInds,[length(featurePts) 1]); % matrix of [1 2 3...] for plot
%   idx = cellfun(@isempty, regexp(featureLabels, 'not')); % false = not an artifact
%   tmp = cellfun(@regexp, featurePtsLabels, repmat(cellstr('not'),[length(featurePtsLabels) 1]), 'UniformOutput', false); % true = not an artifact
%   idx = cellfun(@isempty, [tmp{:}]);
%   scatter(reshape(featureNumbers(idx,:),[],1), reshape(featurePts(idx,:),[],1), 'MarkerEdgeColor', 'k'); hold on;
%   scatter(reshape(featureNumbers(~idx,:),[],1), reshape(featurePts(~idx,:),[],1), 'MarkerEdgeColor', [0.7 0.7 0.7]);
%   %   scatter(reshape(featureNumbers,[],1), reshape(featurePts,[],1), 'MarkerEdgeColor', [0.7 0.7 0.7]);
%   for i = 1: length(clips)
%     h = [];
%     for j = 1: size(channels{i},2)
%       for f = 1: length(funcInds)
%         figure(1); subplot(122); hold on; 
%         h = [h plot(funcInds(f), features{i,funcInds(f)}(j)/maxVals(f), 'o', 'MarkerFaceColor', colors(channels{i}(:,j)))];
%       end 
%       t = (1:length(clips{i}(:,j)))/fs;
%       figure(1); subplot(121); hold on; plot(t, ...
%         -clips{i}(:,j)/max(clips{i}(:,j))/2 + channels{i}(:,j),...
%         colors(channels{i}(:,j))); % axis is reversed to match portal channels
%     end
%     figure(1); subplot(121); axis tight; hold off; title(featurePtsLabels{i}); 
%     day = floor(timesUsec(i,1)/1e6/60/60/24) + 1;
%     leftTime = timesUsec(i,1) - (day-1)*24*60*60*1e6;
%     hour = floor(leftTime/1e6/60/60);
%     leftTime = timesUsec(i,1) - (day-1)*24*60*60*1e6 - hour*60*60*1e6;
%     minute = floor(leftTime/1e6/60);
%     leftTime = timesUsec(i,1) - (day-1)*24*60*60*1e6 - hour*60*60*1e6 - minute*60*1e6;
%     second = floor(leftTime/1e6);
%     xlabel(sprintf('%s   %02d:%02d:%02d:%02d',dataset.snapName, day,hour,minute,second));
%     ylabel('Channel');
%     set(gca,'YDir','reverse','YTick',channels{i});
%     figure(1); subplot(122); xlim([0 funcInds(end)+1]); hold off;
%     xlabel('Feature'); ylabel('Z-score');
%     pause;
%     figure(1); subplot(121); cla;
%     figure(1); subplot(122); delete(h);
%   end

end


% function f_plot1DFeatures(dataset, funcInds, clips, features, channels, featurePts, featurePtsLabels, timesUsec, xyz)
% 
% %  dbstop in f_plot1Dfeatures at 14
%   
%   fs = dataset.sampleRate; % Hz
%   colors = ['r' 'b' 'g' 'y' 'm' 'c' 'k'];
%   maxVals = max(abs(featurePts));
%   featurePts = featurePts./repmat(maxVals, [size(featurePts,1) 1]);
%   featureNumbers = repmat(funcInds,[length(featurePts) 1]); % matrix of [1 2 3...] for plot
%   figure(1); subplot(121); hold on; 
%   figure(1); subplot(122); hold on; 
%   for i = 1: size(xyz,1)
%     plot(funcInds, xyz(i,:), '-+', 'MarkerSize', 12, 'Color', colors(i));
%   end
%   legend('class1', 'class2');
% %   idx = cellfun(@isempty, regexp(featureLabels, 'not')); % false = not an artifact
%   tmp = cellfun(@regexp, featurePtsLabels, repmat(cellstr('not'),[length(featurePtsLabels) 1]), 'UniformOutput', false); % true = not an artifact
%   idx = cellfun(@isempty, [tmp{:}]);
%   scatter(reshape(featureNumbers(idx,:),[],1), reshape(featurePts(idx,:),[],1), 'MarkerEdgeColor', 'k'); hold on;
%   scatter(reshape(featureNumbers(~idx,:),[],1), reshape(featurePts(~idx,:),[],1), 'MarkerEdgeColor', [0.7 0.7 0.7]);
%   %   scatter(reshape(featureNumbers,[],1), reshape(featurePts,[],1), 'MarkerEdgeColor', [0.7 0.7 0.7]);
%   for i = 1: length(clips)
%     h = [];
%     for j = 1: size(channels{i},2)
%       for f = 1: length(funcInds)
%         figure(1); subplot(122); hold on; 
%         h = [h plot(funcInds(f), features{i,funcInds(f)}(j)/maxVals(f), 'o', 'MarkerFaceColor', colors(channels{i}(:,j)))];
%       end 
%       t = (1:length(clips{i}(:,j)))/fs;
%       figure(1); subplot(121); hold on; plot(t, ...
%         -clips{i}(:,j)/max(clips{i}(:,j))/2 + channels{i}(:,j),...
%         colors(channels{i}(:,j))); % axis is reversed to match portal channels
%     end
%     figure(1); subplot(121); axis tight; hold off; title(featurePtsLabels{i}); 
%     day = floor(timesUsec(i,1)/1e6/60/60/24) + 1;
%     leftTime = timesUsec(i,1) - (day-1)*24*60*60*1e6;
%     hour = floor(leftTime/1e6/60/60);
%     leftTime = timesUsec(i,1) - (day-1)*24*60*60*1e6 - hour*60*60*1e6;
%     minute = floor(leftTime/1e6/60);
%     leftTime = timesUsec(i,1) - (day-1)*24*60*60*1e6 - hour*60*60*1e6 - minute*60*1e6;
%     second = floor(leftTime/1e6);
%     xlabel(sprintf('%s   %02d:%02d:%02d:%02d',dataset.snapName, day,hour,minute,second));
%     ylabel('Channel');
%     set(gca,'YDir','reverse','YTick',channels{i});
%     figure(1); subplot(122); xlim([0 funcInds(end)+1]); hold off;
%     xlabel('Feature'); ylabel('Z-score');
%     pause;
%     figure(1); subplot(121); cla;
%     figure(1); subplot(122); delete(h);
%   end
% end