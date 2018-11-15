% [SETTINGS] = CLOUD_CONFIG() returns all cloud settings as specified in
% this configuration code. This is designed to be the single script in
% which all hard-coded customizable cloud settings reside.

function [settings] = cloud_config()
% Google Cloud Platform settings
settings.gcloudMainBucket = 'gs://whisker-autocurator-data'; % Name of your gcloud bucket for this project
settings.gcloudDataBucket = 'gs://whisker-autocurator-data/Data/Curation'; % Cloud directory to upload data for processing
settings.gcloudProjectID = 'whisker-personal-autocurator'; % Google Cloud Platform proejct ID for this project (must be accessible by current cloud user)
settings.gcloudLogDir = 'gs://whisker-autocurator-data/Jobs'; % Cloud directory to store logs from training or curation
settings.runVersion = 1.8; % Runtime version of Cloud ML to use
settings.region = 'us-east1'; % Datacenter to use for processing jobs

% Local directories for data processing use
settings.unprocessedDir = 'C:\SuperUser\CNN_Projects\JK_Pipeline\Datasets'; % Location of unprocessed data
settings.processedDir = 'C:\SuperUser\CNN_Projects\JK_Pipeline\Curated_Datasets'; % Location in which to download unprocessed data from cloud
end