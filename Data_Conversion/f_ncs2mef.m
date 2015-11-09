function [] = f_ncs2mef(animalDir, gapThresh, mefBlockSize)
%   This is a generic function that converts data from the raw binary *.ncs 
%   format to MEF. Each .ncs file contains neural data divided into 512
%   sample blocks, which must be pieced together into .mef.
%   Each .ncs file contains 1) header information, 2) timestamps, 
%   3) channel number, 4) sample frequency, 5) valid samples, and 6) data
%   samples per 512-sample block.
%
%   INPUT:
%       animalDir  = directory with one or more .ncs files for conversion
%       dataBlockLen = amount of data to pull from .eeg at one time, in hrs
%       gapThresh = duration of data gap for mef to call it a gap, in msec
%       mefBlockSize = size of block for mefwriter to wrte, in sec
%
%   OUTPUT:
%       MEF files are written to 'mef\' subdirectory in animalDir, ie:
%       ...animalDir\mef\
%
%   USAGE:
%       f_ncs2mef('Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000',0.1,10000,10);
%
%     
%     dbstop in f_ncs2mef at 87

    % portal time starts at midnight on 1/1/1970
    dateFormat = 'mm/dd/yyyy HH:MM:SS';
    dateOffset = datenum('1/1/1970 0:00:00',dateFormat);  % portal time
    
    % get list of data files in the animal directory
    % remove files that do not match the r###_### naming convention
    % remove .bni, .mat, .txt, .rev files
    NCSList = dir(fullfile(animalDir,'*'));
    removeThese = false(length(NCSList),1);
    for f = 1:length(NCSList)
      if (isempty(regexpi(NCSList(f).name,'.ncs')))
        removeThese(f) = true;
      end
    end
    NCSList(removeThese) = [];

    % confirm there is data in the directory
    assert(length(NCSList) >= 1, '%s: No data found in directory.', animalDir);

    % create output directory (if needed) for mef files
    outputDir = fullfile(animalDir, 'mef');
    if ~exist(outputDir, 'dir');
      mkdir(outputDir);
    end
 
    % extract animal name
    animalName = strsplit(animalDir, '\');
    animalName = [animalName{6} '_' animalName{7}];
    animalName(animalName == ' ') = '_';
        
    % convert each file in the directory (one file == one channel)
    for f = 1:length(NCSList)  
      % read data
      fprintf('file: %s (%d/%d)\n', NCSList(f).name,f,length(NCSList));

      ncsFile = fullfile(animalDir, NCSList(f).name);
      [Timestamps, ChannelNumbers, SampleFrequencies, NumberOfValidSamples, Samples, Header] ...
        = Nlx2MatCSC(ncsFile, [1 1 1 1 1], 1, 1, [] );

      % extract start time
      dateString = Header{strncmp(Header(:,1), '## File Name', 12)};
      dateString = regexp(dateString, '(\d*-\d*-\d*_\d*-\d*-\d*)', 'match');
      startTime = (datenum(dateString, 'yyyy-mm-dd_HH-MM-SS') - dateOffset + 1) * 24 * 3600 * 1e6;

      % confirm sampling frequency, channel name are consistent
      % confirm length(timestamps) == ncol(samples) & num valid samples per
      % block == 512
      assert(isempty(find(diff(SampleFrequencies),1)));
      assert(isempty(find(diff(ChannelNumbers),1)));
      assert(length(Timestamps) == size(Samples,2));
      try
        assert(isempty(find(diff(NumberOfValidSamples),1)) && NumberOfValidSamples(1) == 512);
      catch
        % set invalid samples to NaN - then, remove these samples and
        % associated timestamps prior to mef conversion
        shortRows = find(NumberOfValidSamples ~= 512);
        for i = 1: length(shortRows)
          Samples(NumberOfValidSamples(shortRows(i))+1:end, shortRows) = NaN;
        end
      end
      
      % create time vector from Timestamps and samplingTimes
      % Timestamps = timestamp of the first sample of the 512 sample block
      numSamplesPerBlock = 512; % Neuralynx system configuration
      samplingTimes = (0:numSamplesPerBlock-1) / SampleFrequencies(1) * 1e6;
      samplingTimes = repmat(samplingTimes(:), 1, length(Timestamps));
      Timestamps = repmat(Timestamps - Timestamps(1) + startTime, numSamplesPerBlock, 1);
      timeVec = reshape(samplingTimes + Timestamps, [numel(Samples) 1]);
      
      % create data vector from Samples
      dataVec = reshape(Samples, [numel(Samples) 1]);
      
      % remove invalid samples
      keepThese = ~isnan(dataVec);
      timeVec = timeVec(keepThese);
      dataVec = dataVec(keepThese);
      
      % get metadata from Header 
      conversionFactor = strsplit(Header{~cellfun(@isempty, strfind(Header, 'ADBitVolts'))});
      conversionFactor = str2double(conversionFactor{end})*1e6;
      highFreqFilter = strsplit(Header{~cellfun(@isempty, strfind(Header, 'DspHighCutFrequency'))});
      lowFreqFilter = strsplit(Header{~cellfun(@isempty, strfind(Header, 'DspLowCutFrequency'))});
      
      % open mef file, write metadata to the mef file
      mefFile = fullfile(outputDir, ['Wolf_' animalName '_ch' num2str(ChannelNumbers(1)+1,'%02u') '.mef']);
      try
        h = edu.mayo.msel.mefwriter.MefWriter(mefFile, mefBlockSize, SampleFrequencies(1), gapThresh); 
        h.setSubjectID(animalName);
%       h.setUnencryptedTextField(animalVideo);
        h.setSamplingFrequency(SampleFrequencies(1));
        h.setPhysicalChannelNumber(ChannelNumbers(1));
        h.setVoltageConversionFactor(conversionFactor);
        h.setChannelName(num2str(ChannelNumbers(1)+1,'%02u'));
        h.setHighFrequencyFilterSetting(str2double(highFreqFilter{end}));
        h.setLowFrequencyFilterSetting(str2double(lowFreqFilter{end}));
        h.writeData(dataVec, timeVec, length(dataVec));

      % in case of error be sure to close mef before throwing exception
      catch err
        h.close();
        disp(err.message);
        rethrow(err);
      end
      h.close();
      toc
    end
end