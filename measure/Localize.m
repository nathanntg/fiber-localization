classdef Localize < handle
    %LOCALIZE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        frames_to_discard = 1;
        frames_to_use = 3;
        
        save_frames = true;
    end
    
    properties (Access=protected)
        camera;
        steer;
        fibers;
    end
    
    methods
        function CL = Localize(camera, steer)
            %LOCALIZE Construct an instance of this class
            %   Detailed explanation goes here
            CL.camera = camera;
            CL.steer = steer;
        end
        
        function calibrate(CL)
            CL.steer.calibrate();
        end
        
        function findFibers(CL, varargin)
            if ~CL.steer.isCalibrated()
                error('Steering has not been calibrated.');
            end
            
            CL.fibers = FindFibers();
            CL.fibers.findFibersViaCamera(CL.camera);
        end
        
        function [distances, frames] = localizeFibers(CL, varargin)
            % arguments
            file = [];
            calibrate = [];
            findfibers = [];

            % load arguments
            nparams = length(varargin);
            if 0 < mod(nparams, 2)
                error('Parameters must be specified as parameter/value pairs');
            end
            for i = 1:2:nparams
                nm = lower(varargin{i});
                if ~exist(nm, 'var')
                    error('Invalid parameter: %s.', nm);
                end
                eval([nm ' = varargin{i+1};']);
            end
            
            % defaults
            if isempty(calibrate)
                calibrate = ~CL.steer.isCalibrated();
            elseif ~calibrate && ~CL.steer.isCalibrated() %#ok<BDSCI,BDLGI>
                error('Steering has not been calibrated.');
            end
            if isempty(findfibers)
                findfibers = isempty(CL.fibers);
            elseif ~findfibers && isempty(CL.fibers) %#ok<BDSCI,BDLGI>
                error('Fibers have not been identified.');
            end
            
            % check output
            if nargout == 0 && isempty(file)
                error('Results are not stored or returned.');
            end
            
            % STEP 1: calibrate
            if calibrate
                CL.steer.calibrate();
            end
            
            % STEP 2: find fibers
            if findfibers
                CL.fibers = FindFibers();
                CL.fibers.findFibersViaCamera(CL.camera);
            end
            fibers_xy = CL.fibers.getFibers();
            fibers_num = size(fibers_xy, 1);
            
            % STEP 3: illuminate fibers
            frames = [];
            distances = nan(fibers_num, fibers_num, CL.frames_to_use);
            for i = 1:size(fibers_xy, 1)
                CL.steer.moveTo(fibers_xy(i, 1), fibers_xy(i, 2));
                
                % discard frames
                if CL.frames_to_discard > 0
                    CL.camera.getFrames(CL.frames_to_discard);
                end
                
                % capture frames
                if CL.frames_to_use > 0
                    frames_cur = CL.camera.getFrames(CL.frames_to_use);
                    
                    % store frames?
                    if CL.save_frames
                        frames = cat(ndims(frames_cur) + 1, frames, frames_cur);
                    end
                    
                    b = nan(fibers_num, CL.frames_to_use);
                    if CL.frames_to_use == 1 && size(frames_cur, ndims(frames_cur)) ~= 1
                        % special logic if `getFrames` excludes the singleton
                        % dimension [2048 x 2048 x 1] when fetching just one
                        % frame
                        b(:, 1) = CL.fibers.extractIntensity(frames_cur);
                    else
                        % slice dynamically:
                        % https://stackoverflow.com/questions/22537326/on-shape-agnostic-slicing-of-ndarrays
                        subses = repmat({':'}, [1 ndims(frames_cur)]);
                        
                        % for each frame
                        for j = 1:CL.frames_to_use
                            % extract the intensity for each fiber
                            subses{end} = j;
                            b(:, j) = CL.fibers.extractIntensity(frames_cur(subses{:}));
                        end
                    end
                    
                    % store to distances matrix
                    distances(i, :, :) = b;
                end
            end
            
            % STEP 4: save
            if ~isempty(file)
                [fiber_centers, fiber_radii] = CL.fibers.getFibers();
                save(file, 'distances', 'frames', 'fiber_centers', 'fiber_radii', '-v7.3');
            end
        end
    end
end

