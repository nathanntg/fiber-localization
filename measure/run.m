%% SETUP VIDEO ACQUISITION
% This initializes the camera and opens a camera preview window. For the
% Hamamatsu, the recommended format is (2) 2048 x 2048 slow mode. Even
% better would be (4) 2x2 binning, 1024 x 1024 slow mode, but it does not
% seem to correctly configure the camera for binning.

camera = CameraImageAcquisition.selectCamera();

%% CONFIGURE VIDEO
% Optional. This provides a video source object that can be used to
% configure camera options. Specifically, it is useful to adjust the frame
% rate / exposure time.

vs = camera.getConfiguration();
vs.ExposureTime = 0.01;

%% SETUP GALVO STEERING
% This initializes the data acquisition object for controlling the 2D
% mirror. Simply select the appropriate NI card.

steer = SteerGalvoDataAcquisition.selectGalvo();
steer.setRange([-10 10], [-10 10]);

%% (OPTIONAL) DEBUG GALVO STEERING
% To check galvo alignment, use the commands below to run specific mirror
% movement patterns. View the "SteerGalvoDataAcquisition.m" file for more
% details on arguments to customize scan speed, number of repeats, etc.

steer.debugPoint(0, 0); % move to center point
steer.debugLine(1); % 1 or 2 for which channel to scan
steer.debugSquare();

% Or create a 2D steering interface (opens a window where you can double
% click to steer the laser to a specific point).

ms = ManualSteer(steer);

%% CREATE LOCALIZATION
% Creates localization object that controls both the steering and camera to
% perform fiber localization.

localize = Localize(camera, steer);

%% CALIBRATE
% Step 1: Calibrate the steering. In order to calibrate the 2D mirror, the 
% laser needs to be visualized. To do so, place a fluorescence sample that 
% fills the camera field of view and turn on the laser.

% You will be prompted to press a key before calibration actually starts.

localize.calibrate();

%% FIND FIBERS
% To most easily identify fibers, illuminate the fiber cores using a 
% wavelength visible via the emission filter (e.g., white light). The fiber 
% centers can be discovered using a circle finding algorithm. Once a few
% frames have been acquired:
% 1. A window will open. Double click to annotate a single fiber.
% 2. Close the window.
% 3. Wait... an algorithm will try to find all other fibers.
% 4. The window will re-open showing all fibers found. Add, remove or
%    adjust fibers as needed.
% 5. Close the window.
% 
% You will be prompted to press a key before fiber discover starts.

localize.findFibers();

%% RUN, SAVING OUTPUT TO FILE
% Run fiber localization process. The system will steer the laser to each
% fiber. It will discard 1 frame, and then acquire 3 frames (by default,
% customizable below). The final results will be saved to a MATLAB file for
% inspection, including a distance matrix and (if save_frames is true) the
% actual acquired frames.
%
% Recommendation: only enable save_frames if frames_to_use is 1, otherwise
% too memory intensive.

localize.frames_to_use = 3;
localize.save_frames = false;
localize.localizeFibers('file', 'output.mat');
