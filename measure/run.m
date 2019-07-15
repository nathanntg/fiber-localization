%% SETUP VIDEO ACQUISITION
camera = CameraImageAcquisition.selectCamera();

%% SETUP GALVO STEERING
steer = SteerGalvoDataAcquisition.selectGalvo();
steer.setRange([-10 10], [-10 10]);

%% (OPTIONAL) DEBUG GALVO STEERING
% the following functions can be used to debug galvo steering

steer.debugSquare();

%% CREATE LOCALIZATION
localize = Localize(camera, steer);

%% RUN, SAVING OUTPUT TO FILE
localize.localizeFibers('file', 'output.mat');
