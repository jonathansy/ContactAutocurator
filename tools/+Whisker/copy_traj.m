function copy_traj(ws,tid_to_copy,tid_target)
%
% copy_traj(w,tid_to_copy,tid_target)
%
% Utility function for copying trajectory A data to trajectory B where the latter is missing.
%
% After running this, need to recompute:
%    If ROIs not specified identically for the two tids:
%             -theta, kappa, follicle coords.
%    If ROIs *are* specified identically for the two tids:
%             -follicle coords.
%
%   For example:
%
%   ws.recompute_cached_follicle_coords(extrap_distance, tid)
%
% NOTES: Assumes that the mask (if using a mask) is the same for tid_target and 
%       tid_to_copy.
% 
%
%
% DHO, 3/10.
%


trial = ws;

% ntrials = length(ws.trials);
%
% for k=1:ntrials
%     trial = ws.trials{k};

ind_copy = trial.trajectoryIDs==tid_to_copy;
ind_targ = trial.trajectoryIDs==tid_target;

f_copy = trial.time{ind_copy} / trial.framePeriodInSec;
f_targ = trial.time{ind_targ} / trial.framePeriodInSec;

f_missing = setdiff(f_copy,f_targ);
if isempty(f_missing)
    return
end
for q=1:length(f_missing)
    ind = find(f_targ < f_missing(q),1,'last');
    ind2 = f_copy==f_missing(q);
    trial.polyFits{ind_targ}{1} = [trial.polyFits{ind_targ}{1}(1:ind,:); ...
        trial.polyFits{ind_copy}{1}(ind2,:); trial.polyFits{ind_targ}{1}((ind+1):end,:)]; % X
    trial.polyFits{ind_targ}{2} = [trial.polyFits{ind_targ}{2}(1:ind,:); ...
        trial.polyFits{ind_copy}{2}(ind2,:); trial.polyFits{ind_targ}{2}((ind+1):end,:)]; % Y
    
    trial.polyFitsROI{ind_targ}{1} = [trial.polyFitsROI{ind_targ}{1}(1:ind,:); ...
        trial.polyFitsROI{ind_copy}{1}(ind2,:); trial.polyFitsROI{ind_targ}{1}((ind+1):end,:)]; % X
    trial.polyFitsROI{ind_targ}{2} = [trial.polyFitsROI{ind_targ}{2}(1:ind,:); ...
        trial.polyFitsROI{ind_copy}{2}(ind2,:); trial.polyFitsROI{ind_targ}{2}((ind+1):end,:)]; % Y
    trial.polyFitsROI{ind_targ}{3} = [trial.polyFitsROI{ind_targ}{3}(1:ind,:); ...
        trial.polyFitsROI{ind_copy}{3}(ind2,:); trial.polyFitsROI{ind_targ}{3}((ind+1):end,:)]; % Q
    
    trial.time{ind_targ} = [trial.time{ind_targ}(1:ind) trial.time{ind_copy}(ind2) trial.time{ind_targ}((ind+1):end)];
%     trial.theta{ind_targ} = [trial.theta{ind_targ}(1:ind) trial.theta{ind_copy}(ind2) trial.theta{ind_targ}((ind+1):end)];
%     trial.kappa{ind_targ} = [trial.kappa{ind_targ}(1:ind) trial.kappa{ind_copy}(ind2) trial.kappa{ind_targ}((ind+1):end)];
    
    f_targ = trial.time{ind_targ} / trial.framePeriodInSec;
    
%     if ~isempty(trial.polyFitsMask)
%     trial.polyFitsMask{ind_targ}{1} = [trial.polyFitsMask{ind_targ}{1}(1:ind,:); ...
%         trial.polyFitsMask{ind_copy}{1}(ind2,:); trial.polyFitsMask{ind_targ}{1}((ind+1):end,:)]; % X
%     trial.polyFitsMask{ind_targ}{2} = [trial.polyFitsMask{ind_targ}{2}(1:ind,:); ...
%         trial.polyFitsMask{ind_copy}{2}(ind2,:); trial.polyFitsMask{ind_targ}{2}((ind+1):end,:)]; % Y
%     end
end
% end