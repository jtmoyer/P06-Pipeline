function fig_h = f_histogram_per_rat(snapshot,dataKey,params,fig_h)
%    dbstop in f_histogram_per_rat at 7

%   try
%     load histogram_per_rat.mat;
%   catch
  layer = 1;
  layerName = sprintf('%s-%s',params.label,params.technique);
  while ~strcmp(snapshot.annLayer(layer).name,layerName) && layer < length(snapshot.annLayer)
    layer = layer + 1;
  end
  
  blockSize = 1000; % max number of returned annots is 1000
  numEvents = snapshot.annLayer(layer).getNrEvents();
  annots = snapshot.annLayer(layer).getEvents(1,1000);
  while length(annots) < numEvents
    annots = [annots snapshot.annLayer(layer).getNextEvents(annots(end),blockSize)];
  end
  eventTimes = [annots(1:end).start];
%   eventChannels = cell(1,length(eventTimes));
%   for i = 1:length(eventChannels)
%     eventChannels{i} = annots(i).channels.label;
%   end
%     save histogram_per_rat.mat;
%   end

  figure(1); subplot(3,1,fig_h); hold on;
  eventTimes = eventTimes ./ 1e6 ./ 3600 / 24; % convert to hours
  numHours = snapshot.channels(1).get_tsdetails().getDuration()/1e6/3600;
  hist(eventTimes,numHours);
  label = sprintf('%ss per hour',params.label);
  ylabel(label);
  xlabel('Day of recording');
  title('Rat r099');
%   y_value = 1; % for plotting
%   for i = 1: numel(eventTimes)
%     x = eventTimes*1e-6/3600; % convert to hours
%     x2 = [x; x; nan(1,numel(x))];
%     [m n] = size(x2);
%     x = reshape(x2,1,m*n);
%     y = y_value*ones(1,numel(eventTimes));
%     y2 = [y-0.4; y+0.4; nan(1,numel(y))];
%     [m n] = size(y2);
%     y = reshape(y2,1,m*n);
%     line(x,y,'Color','k');
%     plot(snapshot.channels(1).get_tsdetails().getDuration()/1e6/3600, ...
%       y_value,'*','MarkerEdgeColor','k'); % to show duration of the recording
%     y_value = y_value + 1;
%   end


% figure(fig_h); hold on;
% animal = 1;
% y_value = 1; % for plotting
% plotted = zeros(1,numel(histo.name)); % switch to one when you plot that animal
% while animal <= numel(histo.name)
% %   group = histo.group(animal);
% %   switch char(group)
% %     case 'Hypoxia + Perampanel'
% %       col = 'b';
% %     case 'Vehicle'
% %       col = 'r';
% %     case 'Perampanel'
% %       col = 'g';
% %     case 'Hypox + Vehicle'
% %       col = 'k';
% %   end
%   for i = animal: numel(histo.name)
% %     if (strcmp(histo.group(i), group)) && (plotted(i) == 0)
%       x = histo.annot{i}*1e-6/3600; % convert to hours
%       x2 = [x; x; nan(1,numel(x))];
%       [m n] = size(x2);
%       x = reshape(x2,1,m*n);
%       y = y_value*ones(1,numel(histo.annot{i}));
%       y2 = [y-0.4; y+0.4; nan(1,numel(y))];
%       [m n] = size(y2);
%       y = reshape(y2,1,m*n);
%       line(x,y,'Color','k');
%       plot(histo.endtime{i}*1e-6/3600,y_value,'*','MarkerEdgeColor','k'); % to show duration of the recording
%       labels(y_value) = histo.name(i);
%       plotted(i) = 1;
%       y_value = y_value + 1;
% %     end
%   end
%   animal = animal + 1;
% end

%   set(gca,'YTick',[1:numel(histo.name)]);
%   set(gca,'YTickLabel',labels);
  fig_h = fig_h + 1;
%   ylabel('Bursts per hour');
%   xlabel('Time (Hr)');
%   title('Spike start times for each animal');
end

function [allEvents, timesUSec, channels] = getAllAnnots(dataset,layerName)
% function will return a cell array of all IEEGAnnotation objects in
% annotation layer annLayer

% Input
%   'dataset'   :   IEEGDataset object
%   'layerName'  :   'string' of annotation layer name

% Output
%   'allEvents' :   All annotations
%   'timesUSec' :   Nx2 [start stop] times in USec
%   'channels'  :   cell array of channel idx for each annotation

% Hoameng Ung 6/15/2014
% 8/26/2014 - updated to return times and channels
% 8/28/2014 - changed input to annLayer Str
allEvents = [];
timesUSec = [];
channels = [];
startTime = 1;
allChan = [dataset.channels];
allChanLabels = {allChan.label};
annLayer = dataset.annLayer(strcmp(layerName,{dataset.annLayer.name}));
while true
    currEvents = annLayer.getEvents(startTime,1000);
    if ~isempty(currEvents)
        allEvents = [allEvents currEvents];
        timesUSec = [timesUSec; [[currEvents.start]' [currEvents.stop]']];
        
        ch = {currEvents.channels};
        [~, b] = cellfun(@(x)ismember({x.label},allChanLabels),ch,'UniformOutput',0);
        channels = [channels b];
        
        startTime = currEvents(end).stop+1;
    else
        break
    end
end
end