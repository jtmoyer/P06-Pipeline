function [dataKey, params, featFn] = f_setEnvironment(params)
  %	Usage: [dataKey, params, featFn] = f_setEnvironment(params);
  % Should be called by analyzeDataOnPortal.m
  %	
  %	f_setEnvironment() will load investigator specific information for the
  %	IEEG Pipeline.
  %
  % Input:
  %   params		-	a structure containing at least the following:
  %     params.homeDirectory: eg '~\MATLAB\', a string indicating the home
  %       directory for Matlab.  This directory should include subdirectories
  %       - 'P06-Pipeline' - contains the IEEG pipeline code
  %       - 'P0X-Name-data' - study-specific directory (params.runDir below).
  %         This directory should include the following files:
  %           f_XXXX_dataKey, where XXXX = params.study
  %           f_XXXX_params
  %           f_XXXX_defineFeatures
  %       - 'ieeg-matlab-X.X' - latest version of the IEEG Toolbox, available
  %         here: https://code.google.com/p/braintrust/wiki/Downloads
  %
  % Output:
  %   dataKey - a table with subject index, portal ID, and other info
  %   params  - params structure with applicable fields added to it
  %   featFn  - a cell of feature functions for clustering/classification
  %
  % Jason Moyer 7/20/2015 
  % University of Pennsylvania Center for Neuroengineering and Therapeutics
  %
  % History:
  % 7/20/2015 - v1 - creation
  %.............

  addpath(params.homeDirectory);
  cd(params.homeDirectory);
  addpath(genpath('.\ieeg-matlab-1.8.3'));

  switch params.study
    case 'dichter'
      params.dataDir = 'Z:\public\DATA\Animal_Data\DichterMAD';  % where original data is stored
      params.runDir = '.\P05-Dichter-data';  % investigator specific directory, for .xls, .doc files etc.
    case 'jensen'
      params.dataDir = 'Z:\public\DATA\Animal_Data\Frances_Jensen';  
      params.runDir = '.\P04-Jensen-data';
    case 'chahine'
      params.dataDir = 'Z:\public\DATA\Human_Data\SleepStudies';   
      params.runDir = '.\P03-Chahine-data';
    case 'bumetanide'
      params.dataDir = 'Z:\public\DATA\Animal_Data\Frances_Jensen\Frances_Bumetanide';  
      params.runDir = '.\bumetanide';
  end
  
  addpath(genpath(params.runDir));

  fh = str2func(['f_' params.study '_dataKey']);
  dataKey = fh();

  fh = str2func(['f_' params.study '_params']);
  params = fh(params)
  
  fh = str2func(['f_' params.study '_defineFeatures']);
  featFn = fh();
  
  cd('.\P06-Pipeline\Data_Analysis');
end

