%% SETUP VIDEO ACQUISITION
camera = CameraImageAcquisition.selectCamera();

% configure
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

%% RUN, SAVING OUTPUT TO FILE
localize.localizeFibers('calibrate', true, 'findfibers', true, 'file', 'output.mat');

