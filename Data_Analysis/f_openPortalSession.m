function session = f_openPortalSession(params, dataKey, session)
  %	Usage: session = f_openPortalSession(params, dataKey, session);
  % Called by analyzeDataOnPortal.m
  %	
  % f_openPortalSession() establishes IEEG session and loads all datasets
  % needed for the analysis.
  %
  % Constantly clearing and reestablishing sessions will eventually cause 
  % an out of memory error, so a better way to do it is to only clear and 
  % reload if params.runThese changed.
  %
  % Input:
  %   params    - a structure containing at least the following:
  %     params.runThese - a list of the indices to be used for the analysis
  %   dataKey   -  a table with subject index, portal ID, and other info
  %   session   - IEEG Session variable.  If session is empty,
  %     f_openPortalSessions creates a new session.  If the datasets in
  %     session do not match those in runThese, a new session is created.
  %
  % Output:
  %   session   - IEEG session variable with all datasets in it
  %
  % Jason Moyer 7/20/2015 
  % University of Pennsylvania Center for Neuroengineering and Therapeutics
  %
  % History:
  % 7/20/2015 - v1 - creation
  %.............
  
  if isempty(session)  % load session if it does not exist
    session = IEEGSession(dataKey.portalId{params.runThese(1)},'jtmoyer','jtm_ieeglogin.bin');
    for r = 2:length(params.runThese)
      session.openDataSet(dataKey.portalId{params.runThese(r)});
    end
  else    % clear and reload session if it doesn't have the right datasets
    if (~strcmp(session.data(1).snapName, dataKey.portalId{params.runThese(1)})) || ...
        (length(session.data) ~= length(params.runThese))
      warning('off');
      session = [];
      session = IEEGSession(dataKey.portalId{params.runThese(1)},'jtmoyer','jtm_ieeglogin.bin');
      for r = 2:length(params.runThese)
        session.openDataSet(dataKey.portalId{params.runThese(r)});
      end
      warning('on');
    end
  end
end