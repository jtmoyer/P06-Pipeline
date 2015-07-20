fid = fopen('rat_TBI_data_noheaders.csv');
fdata = textscan(fid,'%d%d%d%d%d%d%d%d%d%d','Delimiter',',');

%split rats into cells
rat = fdata{1}
day = fdata{2}
rburst = fdata{3}
eburst = fdata{4}
spike = fdata{5}
sham = fdata{6}
nonsz = fdata{7}
sz = fdata{8}
group = fdata{9}
exp = fdata{10}

data.rburst = zeros(23,7);
data.eburst = zeros(23,7);
data.spike = zeros(23,7);

for i = 1:23
    data.rburst(i,:) = rburst(rat==i);
    data.eburst(i,:)  = eburst(rat==i);
    data.spike(i,:)  = spike(rat==i);
end

expRats = unique(rat(exp==1));
szRats = unique(rat(sz==1));
nonszRats = unique(rat(nonsz==1));
% simSZrats = 
data.rburst = log(data.rburst+1);
data.eburst = log(data.eburst+1);
data.spike = log(data.spike+1);

[h,p,ci,tr,rr] = calc_T(data.rburst,szRats,nonszRats);
[h,p,ci,te,re] = calc_T(data.eburst,szRats,nonszRats);
[h,p,ci,ts,rs] = calc_T(data.spike,szRats,nonszRats);

szIdx = ismember(expRats,szRats);
combos = nchoosek(expRats,numel(szRats));
nullt_rburst = zeros(size(combos,1),1);
nullt_eburst = zeros(size(combos,1),1);
nullt_spike = zeros(size(combos,1),1);
nullr_rburst = zeros(size(combos,1),1);
nullr_eburst = zeros(size(combos,1),1);
nullr_spike = zeros(size(combos,1),1);

parfor i = 1:size(combos,1)
    nonsz = expRats(~ismember(expRats,combos(i,:)));
    sz = combos(i,:);
    [~,~,~,nullt_rburst(i),nullr_rburst(i)] = calc_T(data.rburst,sz,nonsz);
    [~,~,~,nullt_eburst(i),nullr_eburst(i)] = calc_T(data.eburst,sz,nonsz);
    [~,~,~,nullt_spike(i),nullr_spike(i)] = calc_T(data.spike,sz,nonsz);
end


%two way anova
fid = fopen('rat_TBI_burstduration_noheaders.csv');
fdata = textscan(fid,'%d%f%f%s%s','Delimiter',',');

%split rats into cells
rat = fdata{1}
day = fdata{2}
duration = fdata{3}
group = fdata{4}
outcome = fdata{5}

data.duration = cell(23,1);

uniqueID = unique(rat);
for i = 1:numel(uniqueID)
    id = uniqueID(i);
    data.duration{i} = duration(rat==id);
end

expRats = unique(rat(strcmp(group,'TBI')));
szRats = unique(rat(strcmp(outcome,'SZ')));
nonszRats = unique(rat(strcmp(outcome,'NonSZ')));

IDtoIDX = [1:6 0 7:23]';


[h,p,ci,td,rd] = calc_Tc(data.duration,IDtoIDX(szRats),IDtoIDX(nonszRats));

szIdx = ismember(expRats,szRats);
combos = nchoosek(expRats,numel(szRats));
nullt_duration = zeros(size(combos,1),1);
nullr_duration = zeros(size(combos,1),1);
parfor i = 1:size(combos,1)
    nonsz = expRats(~ismember(expRats,combos(i,:)));
    sz = combos(i,:);
    [~,~,~,nullt_duration(i),nullr_duration(i)] = calc_Tc(data.duration,IDtoIDX(sz),IDtoIDX(nonsz));
end

% iter = 10000;
% nullt_duration = zeros(iter,1);
% for i = 1:iter%size(combos,1)
%     %nonsz = expRats(~ismember(expRats,combos(i,:)));
%     %sz = combos(i,:);
%     rperm = randperm(numel(expRats));
%     nonsz = expRats(rperm(1:9));
%     sz = expRats(rperm(10:end));
%     [~,~,~,nullt_duration(i),nullr_duration(i)] = calc_Tc(data.duration,IDtoIDX(sz),IDtoIDX(nonsz));
% end

%two way anova
%rows: Rat, columns: SZ,nonSZ, values:
szbursttab = [rat(sz==1) eburst(sz==1) zeros(numel(rat(sz==1)),1)];
nonszbursttab = [rat(nonsz==1) zeros(numel(rat(nonsz==1)),1) eburst(nonsz==1)];
bursttab = [szbursttab;nonszbursttab]

