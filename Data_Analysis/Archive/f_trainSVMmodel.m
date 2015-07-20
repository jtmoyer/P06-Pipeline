function model = f_trainSVMmodel(clipsFile,modelFile)

  % load training data and assign labels to it

  clipsFile = fullfile(runDir, sprintf('/Output/seizures-training-data.mat',params.label,params.technique));

  tlabels = zeros(length(featurePts),1);
  k = 1;
  for i = 1: length(features)
    if isempty(strfind(labels{i}, 'artifact'))
      cls = 1; % artifact
    else
      cls = 2; % not an artifact
    end
    for j = 1: length(features{i})
      tlabels(k) = cls;
      k = k + 1;
    end
  end

  trainInds = randperm(length(tlabels));
  tSize = length(tlabels);
  model = svmtrain(tlabels(trainInds(1:tSize)),featurePts(trainInds(1:tSize),:));
end