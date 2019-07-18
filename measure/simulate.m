% This files use simulator classes, no actual hardware. Helps debug the
% underlying algorthms that contribute to the fiber localization process.

%% SETUP VIDEO ACQUISITION
camera = CameraSimulate();

%% SETUP GALVO STEERING
steer = SteerGalvoSimulate(camera);

%% CREATE LOCALIZATION
localize = Localize(camera, steer);
localize.save_frames = false;

%% RUN, DISCARDING OUTPUT
a = localize.localizeFibers();

%% RUN, SAVING OUPUT TO FILE
camera.setMode('localize-fibers');
localize.localizeFibers('file', 'output.mat');