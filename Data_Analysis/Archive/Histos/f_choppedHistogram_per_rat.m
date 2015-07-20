function [fig_h,bstTimes] = f_choppedHistogram_per_rat(snapshot,dataKey,fig_h)
%   dbstop in f_choppedHistogram_per_rat at 67

	fname = sprintf('%s-choppedHistogram.mat',snapshot.snapName);
  try
    load(fname);
  catch    
    blockSize = 1000; % max number of returned annots is 1000

%     layerName = sprintf('spike-noOverlap');
%     layer = 1;
%     while ~strcmp(snapshot.annLayer(layer).name,layerName) && layer < length(snapshot.annLayer)
%       layer = layer + 1;
%     end
%     snapshot.annLayer(layer).name
%     numEvents = snapshot.annLayer(layer).getNrEvents()
%     spkAnnots = snapshot.annLayer(layer).getEvents(1,blockSize);
%     while length(spkAnnots) < numEvents
%       spkAnnots = [spkAnnots snapshot.annLayer(layer).getNextEvents(spkAnnots(end),blockSize)];
%     end
%     spkTimes = [spkAnnots(1:end).start];

    layerName = sprintf('burst_detections');
    layer = 1;
    while ~strcmp(snapshot.annLayer(layer).name,layerName) && layer < length(snapshot.annLayer)
      layer = layer + 1;
    end
    snapshot.annLayer(layer).name
    numEvents = snapshot.annLayer(layer).getNrEvents()
    bstAnnots = snapshot.annLayer(layer).getEvents(1,blockSize);
    while length(bstAnnots) < numEvents
      bstAnnots = [bstAnnots snapshot.annLayer(layer).getNextEvents(bstAnnots(end),blockSize)];
    end
    bstTimes = [bstAnnots(1:end).start; bstAnnots(1:end).stop];

%     layerName = sprintf('seizure-curated');
%     layer = 1;
%     while ~strcmp(snapshot.annLayer(layer).name,layerName) && layer < length(snapshot.annLayer)
%       layer = layer + 1;
%     end
%     snapshot.annLayer(layer).name
%     numEvents = snapshot.annLayer(layer).getNrEvents()
%     szrAnnots = snapshot.annLayer(layer).getEvents(1,blockSize);
%     while length(szrAnnots) < numEvents
%       szrAnnots = [szrAnnots snapshot.annLayer(layer).getNextEvents(szrAnnots(end),blockSize)];
%     end
%     szrTimes = [szrAnnots(1:end).start];

%     save(fname, 'spkTimes','bstTimes','szrTimes');
  end
  
  timescale = 1;  % make it 3600 for hours, 3600/24 for days
  
%   spkTimes = spkTimes / 1e6 / timescale; % convert to days
%   numDays = snapshot.channels(1).get_tsdetails().getDuration()/1e6/timescale;
%   [hspk,spkc] = hist(spkTimes,numDays);
%   figure(1); bar(hspk/2,'FaceColor','k','EdgeColor','k'); hold on;

%   x = spkc(hspk > 50);
%   xx = [floor(x); floor(x); ceil(x); ceil(x)];
%   xxx = reshape(xx, size(xx,1)*size(xx,2), 1);
%   y = [zeros(1,length(x)); ones(1,length(x)); ...
%     ones(1,length(x)); zeros(1,length(x))];
%   yyy = reshape(y,size(y,1)*size(y,2),1);
%   figure(2); patch(xxx,yyy+2*ones(length(yyy),1),'r');
  
  bstTimes = bstTimes / 1e6 / timescale; % convert to days
%   numDays = snapshot.channels(1).get_tsdetails().getDuration()/1e6/timescale;
%   [hbst,bstc] = hist(bstTimes(1,:),numDays);
%   figure(fig_h); bar(hbst,'FaceColor',[0.7 0.7 0.7],'EdgeColor',[0.7 0.7 0.7]); hold on;
%   ylim([0 200]);
%   set(gca,'YTick',[0 50 100 150 200]);
%   title(snapshot.snapName);
  durs = [mean(bstTimes(2,:)-bstTimes(1,:)) std(bstTimes(2,:)-bstTimes(1,:))];

%   x = bstc(hbst > 10);
%   xx = [floor(x); floor(x); ceil(x); ceil(x)];
%   xxx = reshape(xx, size(xx,1)*size(xx,2), 1);
%   y = [zeros(1,length(x)); ones(1,length(x)); ...
%     ones(1,length(x)); zeros(1,length(x))];
%   yyy = reshape(y,size(y,1)*size(y,2),1);
%   figure(2); patch(xxx,yyy+ones(length(yyy),1),'b');

%   szrTimes = szrTimes / 1e6 / timescale; % convert to days
%   numDays = snapshot.channels(1).get_tsdetails().getDuration()/1e6/timescale;
%   [hszr,szrc] = hist(szrTimes,numDays);
%   figure(1); bar(hszr,'FaceColor','r','EdgeColor','r'); hold on;
%   legend('Spikes','Bursts','Seizures'); 

%   
%   x = szrc(hszr > 2);
%   xx = [floor(x); floor(x); ceil(x); ceil(x)];
%   xxx = reshape(xx, size(xx,1)*size(xx,2), 1);
%   y = [zeros(1,length(x)); ones(1,length(x)); ...
%     ones(1,length(x)); zeros(1,length(x))];
%   yyy = reshape(y,size(y,1)*size(y,2),1);
%   figure(2); patch(xxx,yyy,'k');  
%   legend('Spikes','Bursts','Seizures');

  fig_h = fig_h + 1;
end

%   figure(1); subplot(3,1,fig_h); hold on;
%   eventTimes = eventTimes ./ 1e6 ./ 3600 / 24; % convert to hours
%   numHours = snapshot.channels(1).get_tsdetails().getDuration()/1e6/3600;
%   hist(eventTimes,numHours);
%   label = sprintf('%ss per hour',params.label);
%   ylabel(label);
%   xlabel('Day of recording');
%   title('Rat r099');
% %   y_value = 1; % for plotting
% %   for i = 1: numel(eventTimes)
% %     x = eventTimes*1e-6/3600; % convert to hours
% %     x2 = [x; x; nan(1,numel(x))];
% %     [m n] = size(x2);
% %     x = reshape(x2,1,m*n);
% %     y = y_value*ones(1,numel(eventTimes));
% %     y2 = [y-0.4; y+0.4; nan(1,numel(y))];
% %     [m n] = size(y2);
% %     y = reshape(y2,1,m*n);
% %     line(x,y,'Color','k');
% %     plot(snapshot.channels(1).get_tsdetails().getDuration()/1e6/3600, ...
% %       y_value,'*','MarkerEdgeColor','k'); % to show duration of the recording
% %     y_value = y_value + 1;
% %   end
% 
% 
% % figure(fig_h); hold on;
% % animal = 1;
% % y_value = 1; % for plotting
% % plotted = zeros(1,numel(histo.name)); % switch to one when you plot that animal
% % while animal <= numel(histo.name)
% % %   group = histo.group(animal);
% % %   switch char(group)
% % %     case 'Hypoxia + Perampanel'
% % %       col = 'b';
% % %     case 'Vehicle'
% % %       col = 'r';
% % %     case 'Perampanel'
% % %       col = 'g';
% % %     case 'Hypox + Vehicle'
% % %       col = 'k';
% % %   end
% %   for i = animal: numel(histo.name)
% % %     if (strcmp(histo.group(i), group)) && (plotted(i) == 0)
% %       x = histo.annot{i}*1e-6/3600; % convert to hours
% %       x2 = [x; x; nan(1,numel(x))];
% %       [m n] = size(x2);
% %       x = reshape(x2,1,m*n);
% %       y = y_value*ones(1,numel(histo.annot{i}));
% %       y2 = [y-0.4; y+0.4; nan(1,numel(y))];
% %       [m n] = size(y2);
% %       y = reshape(y2,1,m*n);
% %       line(x,y,'Color','k');
% %       plot(histo.endtime{i}*1e-6/3600,y_value,'*','MarkerEdgeColor','k'); % to show duration of the recording
% %       labels(y_value) = histo.name(i);
% %       plotted(i) = 1;
% %       y_value = y_value + 1;
% % %     end
% %   end
% %   animal = animal + 1;
% % end
% 
% %   set(gca,'YTick',[1:numel(histo.name)]);
% %   set(gca,'YTickLabel',labels);
%   fig_h = fig_h + 1;
% %   ylabel('Bursts per hour');
% %   xlabel('Time (Hr)');
% %   title('Spike start times for each animal');
% end

% function [allEvents, timesUSec, channels] = getAllAnnots(dataset,layerName)
% % function will return a cell array of all IEEGAnnotation objects in
% % annotation layer annLayer
% 
% % Input
% %   'dataset'   :   IEEGDataset object
% %   'layerName'  :   'string' of annotation layer name
% 
% % Output
% %   'allEvents' :   All annotations
% %   'timesUSec' :   Nx2 [start stop] times in USec
% %   'channels'  :   cell array of channel idx for each annotation
% 
% % Hoameng Ung 6/15/2014
% % 8/26/2014 - updated to return times and channels
% % 8/28/2014 - changed input to annLayer Str
% allEvents = [];
% timesUSec = [];
% channels = [];
% startTime = 1;
% allChan = [dataset.channels];
% allChanLabels = {allChan.label};
% annLayer = dataset.annLayer(strcmp(layerName,{dataset.annLayer.name}));
% while true
%     currEvents = annLayer.getEvents(startTime,1000);
%     if ~isempty(currEvents)
%         allEvents = [allEvents currEvents];
%         timesUSec = [timesUSec; [[currEvents.start]' [currEvents.stop]']];
%         
%         ch = {currEvents.channels};
%         [~, b] = cellfun(@(x)ismember({x.label},allChanLabels),ch,'UniformOutput',0);
%         channels = [channels b];
%         
%         startTime = currEvents(end).stop+1;
%     else
%         break
%     end
% end
% end