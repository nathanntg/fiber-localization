classdef SteerGalvo < Steer
    %STEERGALVO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        % min / max range for outputs to constrain calibration
        ch1_range = [-1 1];
        ch2_range = [-1 1];
        
        % calibration data
    end
    
    methods
        function CL = SteerGalvo()
            %STEERGALVO Construct an instance of this class
            %   Detailed explanation goes here
            
            % call parent
            CL@Steer();
        end
        
        function calibrate(CL, camera)
            %CALIBRATE Summary of this method goes here
            %   Detailed explanation goes here
            
            % set to mid-point
            ch1 = mean(CL.ch1_range);
            ch2 = mean(CL.ch2_range);
            CL.setValues(ch1, ch2);
        end
        
        function moveTo(CL, x, y)
            % look up in calibration data
            % TODO: write me
        end
    end
    
    methods (Abstract)
        setValues(CL, ch1, ch2);
    end
end
