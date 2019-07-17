%% SETUP VIDEO ACQUISITION
camera = CameraImageAcquisition.selectCamera();

%% CONFIGURE VIDEO
vs = camera.getConfiguration();
vs.ExposureTime = 0.01;

%% SETUP GALVO STEERING
steer = SteerGalvoDataAcquisition.selectGalvo();
steer.setRange([-10 10], [-10 10]);

%% (OPTIONAL) DEBUG GALVO STEERING
% the following functions can be used to debug galvo steering
steer.debugSquare();

%% CREATE LOCALIZATION
localize = Localize(camera, steer);

%% CALIBRATE
localize.calibrate();

%% FIND FIBERS
localize.findFibers();

%% RUN, SAVING OUTPUT TO FILE
localize.frames_to_use = 3;
localize.save_frames = true;
localize.localizeFibers('file', 'output.mat');
