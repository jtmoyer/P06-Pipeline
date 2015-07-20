function params = f_load_params(params)

  switch params.label
    case 'spike'              % spike-threshold
      switch params.technique
        case 'AR'
          params.windowDisplacement = 0;  % just need a value of zero
          params.blockDurMinutes = 30;  % minutes; amount of data to pull at once
          params.smoothDur = 0.3;  % sec; width of smoothing window
          params.spikeThresh = 40;  % spike threshold for residual
          params.minThresh = 0;    % threshold feature must cross for detection - really, anything > 0
          params.minDur = 0.001; % sec, just weeds out
%           params.addAnnotations = 1; % upload annotations to portal
          params.viewData = 0;  % look at the data while it's running?
          params.plotWidth = 0.1; % minutes, if plotting, how wide should the plot be?
          params.saveToDisk = 0;  % save calculations to disk?
      end
    case 'burst'
      switch params.technique
        case 'linelength'     % burst-linelength
          params.function = @(x) (sum(abs(diff(x)))).^2; % sum(x.*x); % feature function
          params.windowLength = 1;         % sec, duration of sliding window
          params.windowDisplacement = 0.5;    % sec, amount to slide window
          params.blockDurMinutes = 30;            % minutes; amount of data to pull at once
          params.smoothDur = 4;   % sec; width of smoothing window
          params.minThresh = 1.5e4; % dichter = 2e4;    % X * stdev(signal); minimum threshold to detect burst; 
          params.minDur = 2;    % sec; min duration of the bursts
%           params.addAnnotations = 1; % upload annotations to portal
          params.viewData = 0;  % look at the data while it's running?
          params.plotWidth = 1; % minutes, if plotting, how wide should the plot be?
          params.saveToDisk = 0;  % save calculations to disk?
      end
    case 'seizure'
      switch params.technique
        case 'energy'     % seizure-area
          params.function = @(x) sum(x.*x); % feature function
          params.windowLength = 2;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurMinutes = 30;            % minutes; amount of data to pull at once
          params.smoothDur = 30;   % sec; width of smoothing window
          params.minThresh = 1e4; % dichter 5e3;    % threshold feature must cross for detection
          params.minDur = 15;    % sec; min duration of the seizures
%           params.addAnnotations = 1; % upload annotations to portal
          params.viewData = 0;  % look at the data while it's running?
          params.plotWidth = 1; % minutes, if plotting, how wide should the plot be?
          params.saveToDisk = 0;  % save feature calculations to disk, vs just the threshold crossings
      end
    case 'seizure10'
      switch params.technique
        case 'energy'     % seizure-area
          params.function = @(x) sum(x.*x); % feature function
          params.windowLength = 2;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurMinutes = 30;            % minutes; amount of data to pull at once
          params.smoothDur = 20;   % sec; width of smoothing window
          params.minThresh = 1e4; % dichter 5e3;    % threshold feature must cross for detection
          params.minDur = 10;    % sec; min duration of the seizures
%           params.addAnnotations = 1; % upload annotations to portal
          params.viewData = 0;  % look at the data while it's running?
          params.plotWidth = 1; % minutes, if plotting, how wide should the plot be?
          params.saveToDisk = 0;  % save feature calculations to disk, vs just the threshold crossings
      end
    case 'seizure20'
      switch params.technique
        case 'energy'     % seizure-area
          params.function = @(x) sum(x.*x); % feature function
          params.windowLength = 2;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurMinutes = 30;            % minutes; amount of data to pull at once
          params.smoothDur = 40;   % sec; width of smoothing window
          params.minThresh = 1e4; % dichter 5e3;    % threshold feature must cross for detection
          params.minDur = 20;    % sec; min duration of the seizures
%           params.addAnnotations = 1; % upload annotations to portal
          params.viewData = 0;  % look at the data while it's running?
          params.plotWidth = 1; % minutes, if plotting, how wide should the plot be?
          params.saveToDisk = 0;  % save feature calculations to disk, vs just the threshold crossings
      end
  end
end