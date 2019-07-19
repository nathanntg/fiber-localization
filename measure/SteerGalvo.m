classdef SteerGalvo < Steer
    %STEERGALVO Generic steering based on 2D galvo
    %   Contains logic needed to calibrate the 2D galvo with the camera. 
    
    properties (Access=protected)
        % started
        started = false;
        
        % min / max range for outputs to constrain calibration
        ch1_range = [-1 1];
        ch2_range = [-1 1];
        
        % calibration data
        calibration = []; % [x y ch1 ch2]
        interp_ch1;
        interp_ch2;
    end
    
    methods
        function CL = SteerGalvo()
            %STEERGALVO Construct an instance of this class
            %   Detailed explanation goes here
            
            % call parent
            CL = CL@Steer();
        end
        
        function setRange(CL, ch1_range, ch2_range)
            if ~isempty(CL.calibration)
                warning('Resetting calibration data.');
                CL.calibration = [];
            end
            
            CL.ch1_range = ch1_range;
            CL.ch2_range = ch2_range;
        end
        
        function calibrate(CL, camera)
            %CALIBRATE Summary of this method goes here
            %   Detailed explanation goes here
            
            % start if needed
            if ~CL.started
                CL.startDevice();
                CL.started = true;
            end
            
            % print guidance
            fprintf('** CALIBRATION **\n');
            fprintf('In order to calibrate the 2D mirror, the laser needs to be visualized.\n');
            fprintf('To do so, place a fluorescence sample that fills the camera field of \n');
            fprintf('view and turn on the laser. Press any key to continue.\n');
            pause;
            
            % calibrate by exploring range
            CL.calibration = CL.calibrateRange(camera);
            
            % build interpolants
            CL.interp_ch1 = scatteredInterpolant(CL.calibration(:, 1), CL.calibration(:, 2), CL.calibration(:, 3), 'linear', 'linear');
            CL.interp_ch2 = scatteredInterpolant(CL.calibration(:, 1), CL.calibration(:, 2), CL.calibration(:, 4), 'linear', 'linear');
            
            % mark as calibrated
            calibrate@Steer(CL, camera);
        end
        
        % debugging functions, useful for calibration
        
        function debugPoint(CL, ch1, ch2)
            % start if needed
            if ~CL.started
                CL.startDevice();
                CL.started = true;
            end
            
            if ch1 < CL.ch1_range(1) || ch1 > CL.ch1_range(2) || ch2 < CL.ch2_range(1) || ch2 > CL.ch2_range(2)
                error('Point out of bounds.');
            end
            
            % set values
            CL.setValues(ch1, ch2);
        end
        
        function debugCalibration(CL)
            % get colors
            colors = hsv(size(CL.calibration, 1));
            
            % open figure
            h = figure;
            h.Position = h.Position .* [1 1 2.1 1];
            
            subplot(1, 2, 1);
            scatter(CL.calibration(:, 1), CL.calibration(:, 2), [], colors);
            xlabel('X');
            ylabel('Y');
            axis square;
            
            subplot(1, 2, 2);
            scatter(CL.calibration(:, 3), CL.calibration(:, 4), [], colors);
            xlabel('Channel 1');
            ylabel('Channel 2');
            axis square;
        end
        
        function moveTo(CL, x, y)
            % look up in calibration data
            [ch1, ch2] = CL.projectXyToValues(x, y);
            
            % check range
            if ch1 < CL.ch1_range(1) || ch1 > CL.ch1_range(2) || ch2 < CL.ch2_range(1) || ch2 > CL.ch2_range(2)
                error('Point %.1f, %.1f is outside accessible range (%.1f, %.1f).', x, y, ch1, ch2);
            end
            
            % move to point
            CL.setValues(ch1, ch2);
        end
        
        function delete(CL)
            % stop if started
            if CL.started
                CL.stopDevice();
            end
        end
    end
    
    methods (Access=protected)
        function startDevice(CL) %#ok<MANU>
        end
        
        function stopDevice(CL) %#ok<MANU>
        end
        
        function calibration = calibrateRange(CL, camera)
            steps_per_axis = 9; % will scan steps 
            
            % assemble channel 1 steps
            a = linspace(0.98 * CL.ch1_range(1), 0.98 * CL.ch1_range(2), steps_per_axis);
            ch1_steps = [];
            for i = 1:steps_per_axis
                if mod(i, 2)
                    ch1_steps = [ch1_steps a]; %#ok<AGROW>
                else
                    ch1_steps = [ch1_steps a(end:-1:1)]; %#ok<AGROW>
                end
            end
            
            % assemble channel 2 steps
            ch2_steps = linspace(0.98 * CL.ch2_range(1), 0.98 * CL.ch2_range(2), steps_per_axis);
            ch2_steps = repelem(ch2_steps, steps_per_axis);
            
            % move laser over points
            calibration = [];
            for i = 1:length(ch1_steps)
                % set value
                CL.setValues(ch1_steps(i), ch2_steps(i));
            
                % get point
                [x, y] = CL.getIlluminationPosition(camera);
                
                % success?
                if ~isempty(x)
                    calibration = [calibration; x y ch1_steps(i) ch2_steps(i)]; %#ok<AGROW>
                end
            end
        end
        
        function [x, y] = getIlluminationPosition(CL, camera)
            % discard frame
            camera.getFrames(1);
            
            % get frame
            frame = camera.getFrames(1);
            
            % get spot position
            try
                [x, y] = findSpot(frame);
            catch
                x = [];
                y = [];
            end
        end
        
        function [ch1, ch2] = projectXyToValues(CL, x, y)
            assert(~isempty(CL.calibration), 'calibration required');
            
            ch1 = CL.interp_ch1(x, y);
            ch2 = CL.interp_ch2(x, y);
        end
    end
    
    methods (Access=protected, Abstract)
        setValues(CL, ch1, ch2);
    end
end
