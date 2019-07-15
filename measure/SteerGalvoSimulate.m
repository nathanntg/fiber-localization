classdef SteerGalvoSimulate < SteerGalvo
    %STEERGALVOSIMULATE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        camera
    end
    
    methods
        function CL = SteerGalvoSimulate(camera)
            %STEERGALVOSIMULATE Construct an instance of this class
            %   Detailed explanation goes here
            
            % call parent
            CL = CL@SteerGalvo();
            
            % set camera
            CL.camera = camera;
        end
        
        function calibrate(CL, camera)
            % set mode for simulation camera
            CL.camera.setMode('calibrate');
            
            % do calibration
            calibrate@SteerGalvo(CL, camera);
            
            % preview calibraiton
            CL.debugCalibration();
            
            % guess next mode
            camera.setMode('find-fibers');
        end
    end
    
    methods (Access=protected)
        function setValues(CL, ch1, ch2)
            x = 540 + 512 .* sign(ch1) .* abs(ch1) ^ 1.3 + 16 .* ch2;
            y = 540 + 8 .* ch1 - 512 .* sign(ch2) .* abs(ch2) ^ 1.4;
            
            CL.camera.setGalvoXY(x, y);
        end
    end
end

