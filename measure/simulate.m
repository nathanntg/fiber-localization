%% SETUP VIDEO ACQUISITION
camera = CameraSimulate();

%% SETUP GALVO STEERING
steer = SteerGalvoSimulate(camera);

%% CREATE LOCALIZATION
localize = Localize(camera, steer);

%% RUN, SAVING OUTPUT TO FILE
localize.localizeFibers('file', 'output.mat');
