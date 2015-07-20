function [h, t, CI, tstat, rstat] = calc_T(data,idx1,idx2)
  dbstop in calc_T at 4

    g1 = data(idx1,:);
    g1 = g1(:);
    g2 = data(idx2,:);
    g2 = g2(:);
    g1(g1==0) = [];
    g2(g2==0) = [];
    [h, t, CI, tSTATS]= ttest2(g1,g2);
    [p,h, rSTATS]= ranksum(g1,g2);
    tstat = tSTATS.tstat;
    rstat = rSTATS.ranksum;
end
