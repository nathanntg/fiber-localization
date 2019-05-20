classdef CameraImageAcquisition < Camera
    %CAMERAIMAGEACQUISITION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        vi
    end
    
    methods
        function CL = CameraImageAcquisition(varargin)
            %CAMERAIMAGEACQUISITION Construct an instance of this class
            %   Arguments: adapter, device_id_or_name, format, properties
            
            % create camera class
            CL@Camera();
            
            % get hardware info
            %hw = imaqhwinfo(adapter);
            
            % create video object
            CL.vi = videoinput(varargin{:});
            
            % start video input
            start(CL.vi);
        end
        
        function delete(CL)
            % stop acquisition
            stop(CL.vi);
            
            % clear video acquisition
            delete(CL.vi);
        end
        
        function frames = getFrames(CL, n)
            % get frames
            frames = getdata(CL.vi, n);
        end
    end
end

