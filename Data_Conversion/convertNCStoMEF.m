%% Dichter_convert.m
% this script will read data from .eeg files (Nicolet format) and convert
% it to .mef format.  The script uses the f_eeg2mef function, which assumes
% data is stored in eeg files in a directory with this kind of path:
% Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000\r097_000.eeg
% output files will be written to ...\DichterMAD\mef\Dichter_r097_01.mef
% for channel 1, ...02.mef for channel 2, etc.

clear all; 
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
javaaddpath('C:\Users\jtmoyer\Documents\MATLAB\java_MEF_writer\MEF_writer.jar');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\NeuralynxMatlabImportExport_v6.0.0'));

% define constants for conversion
study = 'wolf';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [1:2]; % see dataKey indices
dataBlockLenHr = 0.1; % hours; size of data block to pull from .eeg file
mefGapThresh = 1000; % msec; min size of gap in data to be called a gap
mefBlockSize = 0.1; % sec; size of block for mefwriter to write

convert = 1;  % convert data y/n?
test = 0;     % test data y/n?


%% Load investigator data key
switch study
  case 'dichter'
    rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD';
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data';
  case 'jensen'
   rootDir = 'Z:\public\DATA\Animal_Data\Frances_Jensen'; % directory with all the data
   runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data'; 
  case 'chahine'
    rootDir = 'Z:\public\DATA\Human_Data\SleepStudies';   % directory with all the data
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P03-Chahine-data';
  case 'pitkanen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P01-Pitkanen-data')); 
  case 'wolf'
    rootDir = 'Z:\public\DATA\Animal_Data\John_Wolf';
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P07-Wolf-data';
end
addpath(genpath(runDir));
fh = str2func(['f_' study '_dataKey']);
dataKey = fh();


%% convert data from NCS to mef
if convert
  for r = 1: length(runThese)
    animalDir = fullfile(rootDir,char(dataKey.animalId(runThese(r))), ...
      char(dataKey.treatmentGroup(runThese(r))));
    f_ncs2mef(animalDir, mefGapThresh, mefBlockSize);
  end
end


%% compare converted files (on portal) to original
if test
  if ~exist('session','var')  % load session if it does not exist
    session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin','qa');
    for r = 2:length(runThese)
      runThese(r)
      session.openDataSet(dataKey.portalId{runThese(r)});
    end
  else    % clear and throw exception if session doesn't have the right datasets
    if (~strcmp(session.data(1).snapName, dataKey.portalId{runThese(1)})) || ...
        (length(session.data) ~= length(runThese))
      clear all;
      error('Need to clear session data.  Re-run the script.');
    end
  end
  for r = 1: length(session.data)
    fprintf('Loaded %s\n', session.data(r).snapName);
  end  

  for r = 1: length(runThese)
    animalDir = fullfile(rootDir,char(dataKey.animalId(runThese(r))),'2000Hz');
    f_test_eeg2mef(session.data(r), animalDir, dataBlockLenHr);
  end
end



% [Timestamps, ChannelNumbers, SampleFrequencies, NumberOfValidSamples, ...
%   Samples, Header] = Nlx2MatCSC('test.ncs', [1 1 1 1 1], 1, 1, [] );
% 
%   Nlx2MatCSC Imports data from Neuralynx NCS files to Matlab variables.
%  
%     [Timestamps, ChannelNumbers, SampleFrequencies, NumberOfValidSamples,
%     Samples, Header] = Nlx2MatCSC( Filename, FieldSelectionFlags,
%                        HeaderExtractionFlag, ExtractMode, ExtractionModeVector);
%  
%     Version 6.0.0 
%  
%  	Requires MATLAB R2012b (8.0) or newer
%  
%  
%     INPUT ARGUMENTS:
%     FileName: String containing either the complete ('C:\CheetahData\
%               CSC1.ncs') or relative ('CSC1.ncs') path of the file you wish
%               to import. 
%     FieldSelectionFlags: Vector with each item being either a zero (excludes
%                          data) or a one (includes data) that determines which
%                          data will be returned for each record. The order of
%                          the items in the vector correspond to the following:
%                             FieldSelectionFlags(1): Timestamps
%                             FieldSelectionFlags(2): Channel Numbers
%                             FieldSelectionFlags(3): Sample Frequency
%                             FieldSelectionFlags(4): Number of Valid Samples
%                             FieldSelectionFlags(5): Samples
%                          EXAMPLE: [1 0 0 0 1] imports timestamp and samples
%                          data from each record and excludes all other data.
%     HeaderExtractionFlag: Either a zero if you do not want to import the header
%                           or a one if header import is desired..
%     ExtractionMode: A number indicating how records will be processed during
%                     import. The numbers and their effect are described below:
%                        1 (Extract All): Extracts data from every record in
%                          the file.
%                        2 (Extract Record Index Range): Extracts every record
%                          whose index is within a range.
%                        3 (Extract Record Index List): Extracts a specific list
%                          of records based on record index.
%                        4 (Extract Timestamp Range): Extracts every record whose
%                          timestamp is within a range of timestamps.
%                        5 (Extract Timestamp List): Extracts a specific list of
%                          records based on their timestamp.
%     ExtractionModeVector: The contents of this vector varies based on the
%                           ExtractionMode. Each extraction mode is listed with
%                           a description of the ExtractionModeVector contents.
%                        1 (Extract All): The vector value is ignored.
%                        2 (Extract Record Index Range): A vector of two indices,
%                          in increasing order, indicating a range of records to
%                          extract. A record index is the number of the record in
%                          the file in temporal order (i.e. first record is index
%                          1, second is 2, etc.). This range is inclusive of the
%                          beginning and end indices. If the last record in the
%                          range is larger than the number of records in the
%                          file, all records until the end of the file will be
%                          extracted.
%                          EXAMPLE: [10 50] imports the 10th record through the
%                          50th record (total of 41 records) of the file.
%                        3 (Extract Record Index List): A vector of indices
%                          indicating individual records to extract. A record
%                          index is the number of the record in the file in
%                          temporal order (i.e. first record is index
%                          1, second is 2, etc.). Data will be extracted in the
%                          order specified by this vector. If an index in the
%                          vector is less than 1 or greater than the number of
%                          records in the file, the index will be skipped.
%                          EXAMPLE: [7 10 1] imports record 7 then 10 then 1,
%                          it is not sorted temporally
%                        4 (Extract Timestamp Range): A vector of two timestamps,
%                          in increasing order, indicating a range of time to use
%                          when extracting records. If either of the timestamps
%                          in the vector are not contained within the timeframe
%                          of the file, the range will be set to the closest
%                          valid timestamp (e.g. first or last). The range is
%                          inclusive of the beginning and end timestamps. If a
%                          specified timestamp occurs within a record, the entire
%                          record will be extracted. This means that the first
%                          record extracted may have a timestamp that occurs
%                          before the specified start time.
%                          EXAMPLE: [12500 25012] extracts all records that
%                          contain data that occurred between the timestamps
%                          12500 and 25012, inclusive of data at those times.
%                        5 (Extract Timestamp List): A vector of timestamps
%                          indicating individual records to extract. If a
%                          specified timestamp occurs within a record, the entire
%                          record will be extracted. This means that the a record
%                          extracted may have a timestamp that occurs before the
%                          specified timestamp. If there is no data available for
%                          a specified timestamp, the timestamp will be ignored.
%                          Data will be retrieved in the order specified by this
%                          vector.
%                          EXAMPLE: [45032 10125 75000] imports records that
%                          contain data that occurred at timestamp 45035 then
%                          10125 then 75000, it is not sorted temporally.
%  
%     Notes on output data:
%     1. Each output variable's Nth element corresponds to the Nth element in
%        all the other output variables with the exception of the header output
%        variable.
%     2. The value of N in the output descriptions below is the total number of
%        records extracted.
%     3. For more information on Neuralynx records see:
%        http://neuralynx.com/software/NeuralynxDataFileFormats.pdf
%     4. Output data will always be assigned in the order indicated in the
%        FieldSelectionFlags. If data is not imported via a FieldSelectionFlags
%        index being 0, simply omit the output variable from the command.
%        EXAMPLE: FieldSelectionFlags = [1 0 0 0 1];
%        [Timestamps,Samples] = Nlx2MatCSC('test.ncs',FieldSelectionFlags,0,1,[]);
%  
%     OUTPUT VARIABLES:
%     Timestamps: A 1xN integer vector of timestamps.
%     ChannelNumbers: A 1xN integer vector of channel numbers.
%     SampleFrequencies: A 1xN integer vector of sample frequencies.
%     NumberOfValidSamples: A 1xN integer vector of the number of valid samples in the
%                           corresponding item in the Sample output variable.
%     Samples: A 512xN integer matrix of the data points. These values are in AD counts.
%     Header: A Mx1 string vector of all the text from the Neuralynx file header, where
%             M is the number of lines of text in the header.
%  
%  
%     EXAMPLE: [Timestamps, ChannelNumbers, SampleFrequencies,
%               NumberOfValidSamples, Samples, Header] = Nlx2MatCSC('test.ncs',
%                                                        [1 1 1 1 1], 1, 1, [] );
%     Uses extraction mode 1 to return all of the data from all of the records
%     in the file test.ncs.
%  
%     EXAMPLE: [Timestamps, Samples, Header] = Nlx2MatCSC('test.ncs', [1 0 0 0 1],
%                                              1, 2, [14 30]);
%     Uses extraction mode 2 to return the Timestamps and Samples at between
%     record index 14 and 30 as well as the complete file header.
%  