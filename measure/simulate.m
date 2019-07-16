%% SETUP VIDEO ACQUISITION
camera = CameraSimulate();

%% SETUP GALVO STEERING
steer = SteerGalvoSimulate(camera);

%% CREATE LOCALIZATION
localize = Localize(camera, steer);
localize.save_frames = fales;

%% RUN, DISCARDING OUTPUT
a = localize.localizeFibers();

%% RUN, SAVING OUPUT TO FILE
camera.setMode('localize-fibers');
localize.localizeFibers('file', 'output.mat');