classdef Steer < handle
    %STEER Steer the laser to specific 2D coordinates.
    
    properties (Access=protected)
        calibrated = false;
    end
    
    methods
        function CL = Steer()
        end
        
        function calibrated = isCalibrated(CL)
            calibrated = CL.calibrated;
        end
        
        function calibrate(CL, camera)
            % optional calibration step
            CL.calibrated = true;
        end
    end
    
    methods (Abstract)
        moveTo(CL, x, y);
    end
end
