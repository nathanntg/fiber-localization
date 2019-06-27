classdef Steer < handle
    %STEER Steer the laser to specific 2D coordinates.
    
    properties (Access=protected)
    end
    
    methods
        function CL = Steer()
        end
        
        function calibrate(CL, camera)
            % optional calibration step
        end
    end
    
    methods (Abstract)
        moveTo(CL, x, y);
    end
end
