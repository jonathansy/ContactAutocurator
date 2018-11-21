function [trialType, meanBarPos] = assignTrialTypeFromBar(fn)
%
% fn: String giving file name of .bar file.
%
% % %  VARARGIN NOT USED:
% % % % varargin{1}: The frame number to start measuring bar position on.
% % % % varargin{2}: A threshold for bar y-position. If mean position is below
% % %              this threshold, the trial is classified as a no-go.
%              
% 
%
% DHO, 11/09.
%

% fn = 'JF8632_062308_DO79_084.bar';

% figure; plot(b(:,2),'r*'); hold on; plot(b(:,3),'g*')

startFrame = 330; 
thresh = 90; 

b = importdata(fn);

meanBarPos = mean(b(startFrame:end,3)); % y-position of pole center.

if isnan(meanBarPos)
    trialType = 2; % code for error/wildcard
elseif meanBarPos > thresh
    trialType = 1; % go
elseif meanBarPos < thresh
    trialType = 0; % no-go
else
    error('Bar position not determined.')
end

