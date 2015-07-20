function h1 = f_plot3DScatter(featurePts, idx, funcInds)
  % idx == true = an artifact
  %   dbstop in f_plot3DScatter at 9;

  h1 = figure(1);
  if size(funcInds,2) == 1
    bins = min(floor(featurePts)):1:ceil(max(featurePts));
    h = hist(featurePts(~idx,1), bins);
    bar(bins, h, 'FaceColor', 'k'); hold on;
    h = hist(featurePts(idx,1), bins);
    bar(bins, h, 'FaceColor', [0.7 0.7 0.7]);
%     ylim([0 500]); 
    title(sprintf('feature %d',funcInds));
  elseif size(funcInds,2) == 2
    scatter(reshape(featurePts(~idx,1),[],1), reshape(featurePts(~idx,2),[],1), 12, 'k', 'filled'); hold on;
    scatter(reshape(featurePts(idx,1),[],1), reshape(featurePts(idx,2),[],1), 12, [0.7 0.7 0.7], 'filled');
    xlabel('Feature 1'); ylabel('Feature 2');
  elseif size(funcInds,2) >= 2
    scatter3(reshape(featurePts(~idx,1),[],1), reshape(featurePts(~idx,2),[],1), reshape(featurePts(~idx,3),[],1), 12, 'k', 'filled'); hold on;
    scatter3(reshape(featurePts(idx,1),[],1), reshape(featurePts(idx,2),[],1), reshape(featurePts(idx,3),[],1), 12, [0.7 0.7 0.7], 'filled');
    xlabel('Feature 1'); ylabel('Feature 2'); zlabel('Feature 3');
  end
  legend('Event', 'Artifact');
  xlabel('Feature value');
  ylabel('Number of initial detections');
  title('Distribution of initial detections');
  hold off;
%   pause; 
end