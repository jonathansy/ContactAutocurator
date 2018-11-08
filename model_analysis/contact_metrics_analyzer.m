% CONTACT_METRICS_ANALYZER(AUTOCONTA, MANUALCONTA) is a simple function
% for comparing the autocurated version of a contact array with the manual
% version. Can be adapted for different contact array forms. Please supply
% full paths to contact arrays.
function [metrics] = contact_metrics_analyzer(autoConTA, manualConTA, tArray)
  autoCon = load(autoConTA);
  manCon = load(manualConTA);
  T = load(tArray);
  autoCon = autoCon.contacts;
  manCon = manCon.contacts;
  T = T.T;
  % If sizes don't match then the arrays can't be fairly compared
  if length(autoCon) ~= length(manCon)
    error('Contact array size does not match')
  end

  % Loop and establish touches
  numTrials = length(autoCon);
  agreePct = zeros(numTrials, 1); % Total percent  of points in agreement
  agreeNum = zeros(numTrials, 1); % Number of agree upon touches
  falseTouch = zeros(numTrials, 1); % Number of false touch points according to manual curation
  falseNonTouch = zeros(numTrials, 1); % Number of false non-touch points according to manual curation
  onsetDiff = zeros(numTrials, 1); % Average difference between touch onset of agreed touches (in ms)
  offsetDiff = zeros(numTrials, 1); % Average difference between touch offset of agreed touches (in ms)
  %touchDiff = zeros(numTrials, 1); % Total number of touches in trial disagreed upon
  figure(1)
  hold on
  for i = 1:numTrials
      try
          autoPoints = autoCon{i}.contactInds{1};
          manPoints = manCon{i}.contactInds{1};
      catch
          % At least one contact idx failed to load
          agreePct(i) = nan;
          agreeNum(i) = nan;
          falseTouch(i) = nan;
          falseNonTouch(i) = nan;
          onsetDiff(i) = nan;
          offsetDiff(i) = nan;
          %touchDiff(i) = nan;
          continue
      end
    % If both empty, perfect agreement on points
    if isempty(autoPoints) && isempty(manPoints)
      agreePct(i) = 100;
      agreeNum(i) = 0;
      falseTouch(i) = 0;
      falseNonTouch(i) = 0;
      onsetDiff(i) = 0;
      offsetDiff(i) = 0;
      %touchDiff(i) = 0;
      continue
    end

    % Catch empty cells in array, indicating uncuratable due to lack of info
    if strcmp(autoPoints, 'Skipped')
      % No distance to pole data for trial or missing vid, uncuratable
      agreePct(i) = nan;
      agreeNum(i) = nan;
      falseTouch(i) = nan;
      falseNonTouch(i) = nan;
      onsetDiff(i) = nan;
      offsetDiff(i) = nan;
      %touchDiff(i) = nan;
      continue
    end

    % Process actual points
    commonTouches = intersect(autoPoints, manPoints);
    falseTouch(i) = numel(autoPoints) - numel(commonTouches);
    falseNonTouch(i) = numel(manPoints) - numel(commonTouches);
    agreePct(i) = 100*((4000 - falseTouch(i) - falseNonTouch(i))/4000);
    vel = nanmean(abs(diff((T.trials{i}.whiskerTrial.distanceToPoleCenter{1}))));
    scatter(vel, agreePct(i), 70, 'r', '.');

    % Find onsets
    if ~isempty(autoPoints)
        autoOnset = find(diff(autoPoints) > 1);
        autoOffset = autoOnset;
        autoOnset = autoOnset + 1;
        autoOnset = [1 autoOnset];
        autoOnsetPts = autoPoints(autoOnset);
        autoOffsetPts = [autoPoints(autoOffset) autoPoints(end)];
    else
        autoOnsetPts = [];
    end
    if ~isempty(manPoints)
    manOnset = find(diff(manPoints) > 1);
    manOffset = manOnset;
    manOnset = manOnset + 1;
    manOnset = [1 manOnset];
    manOnsetPts = manPoints(manOnset);
    manOffsetPts = [manPoints(manOffset) manPoints(end)];
    else
        manOnsetPts = [];
    end
    if isempty(commonTouches) 
        agreeNum(i) = 0;
    elseif ~isempty(autoPoints) && ~isempty(manPoints)
        commonOnset = find(diff(commonTouches) > 1);
        commonOffset = commonOnset;
        commonOnset = commonOnset + 1;
        commonOnset = [1 commonOnset];
        commonOnsetPts = commonTouches(commonOnset);
        commonOffsetPts = [commonTouches(commonOffset) commonTouches(end)];
        numCommonTouch = numel(commonOnset);
        agreeNum(i) = numCommonTouch;
        onsetDelta = zeros(1, numCommonTouch);
        offsetDelta = zeros(1, numCommonTouch);
        % Loop through touches
        for j = 1:numCommonTouch
            % Find difference between onset points
            onsetPt = commonOnsetPts(j);
            [~,autoDiff] = min(abs(autoOnsetPts - onsetPt));
            [~,manDiff] = min(abs(manOnsetPts - onsetPt));
            onsetDelta(j) = abs(autoDiff - manDiff);
            % Find difference between offset points
            offsetPt = commonOffsetPts(j);
            [~,autoDiff] = min(abs(autoOffsetPts - offsetPt));
            [~,manDiff] = min(abs(manOffsetPts - offsetPt));
            offsetDelta(j) = abs(autoDiff - manDiff);
        end
        onsetDiff(i) = mean(onsetDelta);
        offsetDiff(i) = mean(offsetDelta);
    else
        agreeNum(i) = 0;
    end
  end
  % Calcualte statistics
  axis([0 0.08 75 100])
  xlabel('Velocity')
  ylabel('Agreement')
  %hold off
  metrics.percentAgreedPoints = nanmean(agreePct);
  metrics.totalFalseTouchErrors = nansum(falseTouch);
  metrics.totalMissedTouchErrors = nansum(falseNonTouch);
  onsetError = nansum(onsetDiff.*agreeNum)/nansum(agreeNum);
  metrics.onsetError = onsetError;
  offsetError = nansum(offsetDiff.*agreeNum)/nansum(agreeNum);
  metrics.offsetError = offsetError;
