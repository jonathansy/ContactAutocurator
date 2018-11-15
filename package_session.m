% [CURATIONARRAY] = PACKAGE_SESSION(VIDEODIR, DATADIR) returns a single 
% structure (CURATIONARRAY) with all relevant data for training and 
% curation. VIDEODIR is the path to a session of whisker video while
% DATADIR is the path to all tracking data. It is designed to be used with 
% the Janelia Farm whisker Tracker

% Created: 2018-11-12 by J. Sy
% Last Updated: 2018-11-12 by J. Sy

function [curationArray] = package_session(videoDir, dataDir)
