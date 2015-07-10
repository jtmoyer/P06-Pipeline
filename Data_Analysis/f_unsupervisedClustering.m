function allData = f_unsupervisedClustering(session, allData, funcInds, runThese, params, runDir, threshold)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%    dbstop in f_unsupervisedClustering at 11

  %.....
  % code that sets a threshold and removes detections above it
  featurePts = [];
  for r = 1: length(runThese)
    featurePts = [featurePts; reshape([allData(r).features{:,funcInds}], {}, length(funcInds))];
  end
  
%     featurePts = (featurePts - mean(featurePts)) / std(featurePts);
    
  try

    % %  code for thresholding
%     binWidth = (max(featurePts)-min(featurePts)) / 20;
  binWidth = 1;
  bins = floor(min(featurePts)):binWidth:ceil(max(featurePts));
  h1 = hist(featurePts, bins);
%   bar(bins, h1);
%     localMinima = [false diff(sign(diff(h1))) > 0 true];
%   topTwoThirds = (1:nbins) > nbins/3;
%     atLeast = bins > 0.5;
%     aboveMedian = bins > hist(median(featurePts),bins);
%     aboveInflection = logical([0 0 0 diff(sign(diff(diff(h1)))) > 0]);
% inflection point: when second derivative changes from negative to positive
% ie, diff(sign(second derivative)) > 0
%     thresh = bins(aboveInflection);
  thresh = bins(bins > threshold);
  thresh = thresh(1) - binWidth/2;  % set thresh to left edge
  fprintf('%s: threshold = %0.3f\n', session.data(r).snapName, thresh);
% remove values greater than threshold
% too look at what's being removed on portal, switch to a <=
  catch
    thresh = max(featurePts) + 1; % don't remmove anything
  end
  if params.lookAtArtifacts
    cIdx = (featurePts <= repmat(thresh, length(featurePts), 1));
  else
    cIdx = (featurePts > repmat(thresh, length(featurePts), 1));
  end

% %  code for gaussian mixture model
%       gmFit = gmdistribution.fit(featurePts(featurePts<100),2);
%       cIdx = logical(cluster(gmFit, featurePts) - 1);

  if params.plot3DScatter 
    try
      h = f_plot3DScatter(featurePts, cIdx, funcInds);
    catch
    end
    print(h, fullfile(runDir, 'output', 'Figures', [session.data(r).snapName '_scatter.png']), '-dpng');
  end
  
  % set artifact points to 1, non artifacts to 0
  c = 1;
  for r = 1:length(runThese)
    try
      allData(r).classes = cell(size(allData(r).channels));
      for i = 1: size(allData(r).channels,1)
        allData(r).classes{i} = cIdx(c:c+size(allData(r).channels{i},2)-1);
        % featureClasses(i) = round(mean(cIdx(c:c+size(allData(r).channels{i},2)-1)));
        c = c + size(allData(r).channels{i},2);
      end
      if params.plot1DFeatures
        f_plot1DFeatures(session.data(r), allData(r), funcInds, featureClasses);
      end
    catch
    end
  end

%   % get rid of the data points in allData that are artifact
%   % cIdx is classes vector; collapse to dimensions of allData.channels
%   % if any channel has artifact, call them all artifact to avoid crosstalk
%   c = 1;
%   for r = 1:length(runThese)
%     try
%       featureClasses = NaN(size(allData(r).channels));
%       for i = 1: size(allData(r).channels,1)
%         if params.lookAtArtifacts 
%           featureClasses(i) = all(cIdx(c:c+size(allData(r).channels{i},2)-1) == ones(length(allData(r).channels{i}),1));
%         else
%           featureClasses(i) = any(cIdx(c:c+size(allData(r).channels{i},2)-1) == ones(length(allData(r).channels{i}),1));
%         end
%           
%         % featureClasses(i) = round(mean(cIdx(c:c+size(allData(r).channels{i},2)-1)));
%         c = c + size(allData(r).channels{i},2);
%       end
%       if params.plot1DFeatures
%         f_plot1DFeatures(session.data(r), allData(r), funcInds, featureClasses);
%       end
% 
%       fprintf('%s: Removing %d/%d annotations.\n', session.data(r).snapName, length(find((featureClasses))), length(featureClasses));
% 
%       allData(r).channels = {allData(r).channels{logical(~featureClasses)}}';
%       allData(r).timesUsec = (allData(r).timesUsec(logical(~featureClasses),:));
%       allData(r).features = reshape({allData(r).features{logical(~featureClasses),:}},[],size(allData(r).features,2));
%     catch
%     end
%   end
end
%.....

  
