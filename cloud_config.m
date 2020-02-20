% [SETTINGS] = CLOUD_CONFIG() returns all cloud settings as specified in
% this configuration code. This is designed to be the single script in
% which all hard-coded customizable cloud settings reside.

function [settings] = cloud_config()
% Google Cloud Platform settings
settings.mainBucket = 'gs://whisker-autocurator-data'; % Name of your gcloud bucket for this project
settings.dataBucket = 'gs://whisker-autocurator-data/Data/Curation'; % Cloud directory to upload data for processing
settings.projectID = 'whisker-personal-autocurator'; % Google Cloud Platform proejct ID for this project (must be accessible by current cloud user)
settings.logDir = 'gs://whisker-autocurator-data/Jobs'; % Cloud directory to store logs from training or curation
settings.models = 'gs://whisker-autocurator-data/Models'; % Place to store your cloud models
settings.runVersion = 1.8; % Runtime version of Cloud ML to use
settings.region = 'us-east1'; % Datacenter to use for processing jobs, us-central1 (Iowa) or us-east1 (South Carolina) is required to use TPUs and best GPUs

end