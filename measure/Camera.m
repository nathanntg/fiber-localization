classdef Camera < handle
    %CAMERA Camera acquisition class to acquire camera images.
    
    properties (Access=protected)
    end
    
    methods
        function CL = Camera()
        end
    end
    
    methods (Abstract)
        frames = getFrames(CL, n);
    end
end

