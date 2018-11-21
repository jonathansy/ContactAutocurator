function [tifFileNums,behavTrialNums,trialTypes] = imageFileNums2BehavTrialNums(b,v)

%----------------------


n = v(:,1)';
t = b.trialTypes;
x = v(:,2)';

% xwild = 2*cellfun(@(x) strcmp(x(9),'.'), v)';
% x = x + xwild;

ts = num2str(t); ts = ts(~isspace(ts));
xs = num2str(x); xs = xs(~isspace(xs));
xs = strrep(xs,'2','.');

k=regexp(ts,xs);
if length(k) > 1
    error('Ambigous match!')
elseif isempty(k)
    error('No match!')
end
xxs = [repmat(' ',1, k-1) xs repmat(' ', 1, length(ts)-(length(xs) + k-1))];
disp([ts; xxs])
xTrialNums = b.trialNums(k:(k+length(xs)-1))';

% Restrict output to only those files/trials without wildcard trial type:
missingTrialTypeInds = find(x==2);
keepInds = setdiff(1:length(n), missingTrialTypeInds);
n = n(keepInds)'; xTrialNums = xTrialNums(keepInds);

disp('Image_file_number  Behavior_trial_number')
disp([n xTrialNums])

tifFileNums = n; behavTrialNums = xTrialNums; 
trialTypes = x(keepInds)';  %% Add 

