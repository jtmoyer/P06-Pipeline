function allData = f_removeAnnotations(session, allData, featFn, useTheseFeatures, scrub)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
% scrub is a 0 or 1
%   dbstop in f_removeAnnotations at 9
  
  featFn(useTheseFeatures)
  useData = allData;
  for u = 1: length(useTheseFeatures)
    f = 1; % useTheseFeatures(u);
    for r = 1: size(allData,1)
      for a = size(allData(r).classes,1): -1: 1
%         if params.lookAtArtifacts
%           removeIdx = find(allData(r).classes{a,f} == 1);
%         else
        removeIdx = find(allData(r).classes{a,f} == 1);
%         end
        if length(removeIdx) == length(allData(r).classes{a,f}) || ...
          (~isempty(removeIdx) && scrub)
          allData(r).channels(a) = [];
          allData(r).timesUsec(a,:) = [];
          allData(r).features(a,:) = [];
          allData(r).labels(a,:) = [];
          allData(r).classes(a,:) = [];
        else
          for i = 1: size(allData(r).features,2)
            allData(r).features{a,i}(removeIdx) = [];
          end
          allData(r).channels{a}(removeIdx) = [];
          allData(r).classes{a}(removeIdx) = [];
        end
      end
    end
  end
  for r = 1: length(session.data)
    fprintf('%s: Removed %d/%d annotations.\n', session.data(r).snapName, (size(useData(r).timesUsec,1)-size(allData(r).timesUsec,1)), size(useData(r).timesUsec,1));
  end
end

