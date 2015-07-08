function f_uploadAnnotations(dataset,layerName,eventTimesUSec,eventChannels,label)
%	Usage: uploadAnnotations(dataset, layerName, eventTimesUSec,eventChannels,label);
%	
%	dataset		-	IEEGDataset object
%	layerName	-	string of name of annotation layer
%	eventTimesUSec	-	array of event times in microsec
%	eventChannels	-	cell array of channel indices corresponding to each event
%	label		-	string label for events
%
%	Function will upload to the IEEG portal the given events obtained from running various detection
%	algorithms (e.g. spike_AR.m). Annotations will be associated with eventChannels and given a label.
%files(d).name(1:15)
%   v2 3/15/2015 - Hoameng Ung - added variable channel support
%   
%   dbstop in f_uploadAnnotations at 26;
  try
    ann = [];
%     fprintf('Creating annotations...');
    %create cell array of unique channels in eventChannels
    strEventChannels = cellfun(@num2str,eventChannels,'UniformOutput',0);
    uniqueChannels = unique(strEventChannels);
    uniqueChannels = cellfun(@str2num,uniqueChannels,'UniformOutput',0);
    for i = 1:numel(uniqueChannels)
        idx = cellfun(@(x)isequal(x,uniqueChannels{i}),eventChannels);
        tmpChan = uniqueChannels(i);
        ann = [ann IEEGAnnotation.createAnnotations(eventTimesUSec(idx,1),eventTimesUSec(idx,2),'Event',label(idx),dataset.channels(uniqueChannels{i}))];
    end
%     fprintf('done!\n');
    numAnnot = numel(ann);
    startIdx = 1;
    %add annotations 5000 at a time (freezes if adding too many)
    try 
  %       fprintf('\n%s: Removing existing layer: %s\n', dataset.snapName, layerName);
        dataset.removeAnnLayer(layerName);
    catch 
  %       fprintf('No existing layer\n');
    end
    annLayer = dataset.addAnnLayer(layerName);
    fprintf('%s: Adding %d annotations to layer %s...\n', dataset.snapName, numAnnot, layerName);
    for i = 1:ceil(numAnnot/5000)
%         fprintf('Adding %d to %d\n',startIdx,min(startIdx+5000,numAnnot));
        annLayer.add(ann(startIdx:min(startIdx+5000,numAnnot)));
        startIdx = startIdx+5000;
    end
%     fprintf('done!\n');
  catch err
    fprintf('No annotations uploaded.\n');
    rethrow(err);
  end
end