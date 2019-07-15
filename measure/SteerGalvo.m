classdef SteerGalvo < Steer
    %STEERGALVO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        % started
        started = false;
        
        % min / max range for outputs to constrain calibration
        ch1_range = [-1 1];
        ch2_range = [-1 1];
        
        % calibration data
        calibration = []; % [x y ch1 ch2]
    end
    
    methods
        function CL = SteerGalvo()
            %STEERGALVO Construct an instance of this class
            %   Detailed explanation goes here
            
            % call parent
            CL = CL@Steer();
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
            
            % build a quick calibration matrix
            calibration_quick = CL.calibrationFirstPoint(camera);
            calibration_quick = CL.calibrationAdditionalPoints(camera, calibration_quick);
            
            % build detailed calibration matrix
            calibration_detailed = CL.calibrationGrid(camera, calibration_quick);
            
            % store calibration
            CL.calibration = calibration_detailed;
            
            % mark as calibrated
            calibrate@Steer(CL, camera);
        end
        
        function moveTo(CL, x, y)
            % look up in calibration data
            [ch1, ch2] = CL.projectXyToValues(x, y);
            
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
        
        function row = calibrationFirstPoint(CL, camera)
            % store range
            step1 = (CL.ch1_range(2) - CL.ch1_range(1)) / 5;
            step2 = (CL.ch2_range(2) - CL.ch2_range(1)) / 5;
            
            % set to mid-point
            mid1 = mean(CL.ch1_range);
            mid2 = mean(CL.ch2_range);
            
            % points
            points = [mid1 mid2];
            for i = 0:2
                for j = 0:2
                    % already added above
                    if i == 0 && j == 0
                        continue;
                    end
                    
                    % could add +- and -+, but probably not worth it
                    points = [points; mid1 + i * step1 mid2 + j * step2; mid1 - i * step1 mid2 - j * step2]; %#ok<AGROW>
                end
            end
            
            % try each point
            for i = 1:size(points, 1)
                % get ch1 and ch2 values from list
                ch1 = points(i, 1);
                ch2 = points(i, 2);
                
                % set value
                CL.setValues(ch1, ch2);
            
                % get point
                [x, y] = CL.getIlluminationPosition(camera);
                
                if ~isempty(x)
                    row = [x, y, ch1, ch2];
                    return;
                end
            end
            
            % none found
            error('Calibration failed: unable to find illumination position.');
        end
        
        function new_calibration = calibrationAdditionalPoints(CL, camera, calibration)
            % store range
            step1 = (CL.ch1_range(2) - CL.ch1_range(1)) / 5;
            step2 = (CL.ch2_range(2) - CL.ch2_range(1)) / 5;
            
            % initial calibration point
            ch1 = calibration(1, 3);
            ch2 = calibration(1, 4);
            
            % try smaller and smaller steps
            for i = 0:4
                % allow positive or negative shifts
                for j = [1 -1]
                    % calculate shifted point
                    new_ch1 = ch1 + j * step1 / (2 ^ i);
                    new_ch2 = ch2 + j * step2 / (2 ^ i);

                    % set value
                    CL.setValues(new_ch1, new_ch2);

                    % get point
                    [x3, y3] = CL.getIlluminationPosition(camera);
                    
                    % success? get all points
                    if ~isempty(x3)
                        CL.setValues(new_ch1, ch2);
                        [x1, y1] = CL.getIlluminationPosition(camera);
                        
                        CL.setValues(ch1, new_ch2);
                        [x2, y2] = CL.getIlluminationPosition(camera);
                        
                        if isempty(x1) || isempty(x2)
                            error('Calibration failed: x/y shift found, but not partial shift.');
                        end
                        
                        % make new calibration array
                        new_calibration = [calibration; ...
                            x1 y1 new_ch1 ch2; ...
                            x2 y2 ch1 new_ch2; ...
                            x3 y3 new_ch1 new_ch2];
                        
                        return;
                    end
                end
            end
            
            % none found
            error('Calibration failed: unable to find shifted position.');
        end
        
        function [x, y] = getIlluminationPosition(CL, camera)
            % discard frame
            camera.getFrames(1);
            
            % get frame
            frame = camera.getFrames(1);
            
            % get spot position
            [x, y] = getSpot(frame);
        end
        
        function [ch1, ch2] = moveIlluminationTo(CL, camera, calibration, x, y)
            % ASSUMES CALIBRATION COMES FROM `calibrationAdditionalPoints`
            basis1 = calibration(2, :) - calibration(1, :);
            basis2 = calibration(3, :) - calibration(1, :);
            if dot(basis1([3 4]), basis2([3 4])) > eps
                error('Expected calibration matrix with orthogonal steps in rows 1-2 and rows 1-3.');
            end
            
            % normalize, effect of steps along basis
            basis1 = basis1 ./ norm(basis1([3 4]));
            basis2 = basis2 ./ norm(basis2([3 4]));
            
            A = [basis1([1 2]); basis2([1 2])];
            
            % find closest point in calibration data
            [~, idx] = min(sum(bsxfun(@minus, calibration(:, [1 2]), [x y]) .^ 2, 2));
            known = calibration(idx, :);
            
            for j = 1:20
                % measure distance from previous known point
                distance = [x y] - known([1 2]);
                
                % if within desired distance, return channel values
                if norm(distance) <= 4
                    ch1 = known(3);
                    ch2 = known(4);
                    return;
                end

                % figure out how to alter channel values to move by desired
                % distance
                step = linsolve(A, distance');

                % update channel position from the previous known point
                ch = known([3 4]) + step(1) .* basis1([3 4]) + step(2) .* basis2([3 4]);

                % update mirror position
                CL.setValues(ch(1), ch(2));

                % figure out laser point
                [spot_x, spot_y] = CL.getIlluminationPosition(camera);
                
                % in case we left the FOV?
                if isempty(spot_x)
                    % try half step
                    step = step ./ 2;
                    ch = known([3 4]) + step(1) .* basis1([3 4]) + step(2) .* basis2([3 4]);

                    % update mirror position
                    CL.setValues(ch(1), ch(2));
                    
                    % figure out laser point
                    [spot_x, spot_y] = CL.getIlluminationPosition(camera);
                end

                % update closest point
                known = [spot_x spot_y ch];
            end
            
            error('The `moveIlluminationTo` did not converge to the desired point.');
        end
        
        function [ch1, ch2] = projectXyToValues(CL, x, y)
            assert(~isempty(CL.calibration), 'calibration required');
            
            ch1 = interp2(CL.calibration(:, 1), CL.calibration(:, 2), CL.calibration(:, 3), x, y, 'makima');
            ch2 = interp2(CL.calibration(:, 1), CL.calibration(:, 2), CL.calibration(:, 4), x, y, 'makima');
        end
    end
    
    methods (Access=protected, Abstract)
        setValues(CL, ch1, ch2);
    end
end
