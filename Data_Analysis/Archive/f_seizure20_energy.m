function output = f_seizure20_energy(data, params, fs, curTime)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_seizure_energy at 39

  %%-----------------------------------------
  %%---  feature creation and data processing
  % calculate number of sliding windows (overlap is ok)
  NumWins = @(xLen, fs, winLen, winDisp) (xLen/fs)/winDisp-(winLen/winDisp-1); 
  nw = int64(NumWins(length(data), fs, params.windowLength, params.windowDisplacement));
  timeOut = zeros(nw,1);
  featureOut = zeros(nw, length(params.channels));

  % filter then normalize each channel by std of entire data block
  origData = data;
  data = high_pass_filter(data, fs);
  filtOut = data ./ repmat(rms(data,1),size(data,1),1);
%   normalizer = max(std(data)) ./ std(data);
%   for c = 1: length(params.channels)
%     data(:,c) = data(:,c) .* normalizer(c);
%   end

%   % high-pass filter
%   filtOut = high_pass_filter(data, fs); % see below

  % for each window, calculate feature as defined in params
  for w = 1: nw
    winBeg = params.windowDisplacement * fs * (w-1) + 1;
    winEnd = min([winBeg+params.windowLength*fs-1 length(filtOut)]);
    timeOut(w) = winEnd/fs*1e6 + curTime;         % right-aligned
    featureOut(w,:) = params.function(filtOut(winBeg:winEnd,:)); 
  end

  % smooth window using convolution 
  if params.smoothDur > 0
    smoothLength = 1/params.windowDisplacement * params.smoothDur; % in samples of data signal
    smoother =  1 / smoothLength * ones(1,smoothLength);
    for c = 1: length(params.channels)
      featureOut(:,c) = conv(featureOut(:,c),smoother,'same');
    end
  end
  output = [timeOut featureOut];
  %%---  feature creation and data processing
  %%-----------------------------------------
end


function y = high_pass_filter(x, Fs)
  % MATLAB Code
  % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
  % Generated on: 04-Mar-2015 10:14:48

  persistent Hd;

  if isempty(Hd)

    N     = 3;    % Order
    F3dB  = 4;     % 3-dB Frequency
    Apass = 1;     % Passband Ripple (dB)

    h = fdesign.highpass('n,f3db,ap', N, F3dB, Apass, Fs);

    Hd = design(h, 'cheby1', ...
      'SOSScaleNorm', 'Linf');

    set(Hd,'PersistentMemory',true);

  end
  
  y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
%   y = filtfilt(h,x);
end

