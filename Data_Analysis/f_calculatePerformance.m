function scores = f_calculatePerformance(session, runThese, outputLayer, testingPrefix)

%   dbstop in f_calculatePerformance at 13

  outputEvents = [];
  testEvents = [];
  testArtifacts = [];
  scores.truePositive = 0;
  scores.falsePositive = 0;
  scores.trueNegative = 0;
  scores.falseNegative = 0;

  for r = 1: length(runThese)
    try
      outputEvents = f_getAllAnnots(session.data(r), outputLayer);
    catch
    end
    try
      testEvents = f_getAllAnnots(session.data(r), sprintf('%s-event', testingPrefix));
    catch
    end
    try
      testArtifacts = f_getAllAnnots(session.data(r), sprintf('%s-artifact', testingPrefix));
    catch
    end
  
    % if it's in outputEvents - it's a detection
    % if not, it's an artifact
    try
      startTimes = [outputEvents.start];
      for i = 1: length(testEvents)
        if ismember(testEvents(i).start, startTimes)
          scores.truePositive = scores.truePositive + 1;
        else
          scores.falseNegative = scores.falseNegative + 1;
        end
      end
    catch
    end

    try
      for i = 1: length(testArtifacts)
        if ismember(testArtifacts(i).start, startTimes)
          scores.falsePositive = scores.falsePositive + 1;
        else
          scores.trueNegative = scores.trueNegative + 1;
        end
      end
    catch
    end
  end
end
