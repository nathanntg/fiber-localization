classdef CameraSimulate < Camera
    %CAMERASIMULATE Camera acquisition class to acquire camera images.
    
    properties (Access=protected)
        width = 1024;
        height = 1024;
        
        mode = 'localize-fibers'; % 'calibrate', 'find-fibers', 'localize-fibers'
        
        galvo_xy = [0 0];
    end
    
    methods
        function CL = CameraSimulate()
            % create camera class
            CL = CL@Camera();
        end
        
        function setGalvoXY(CL, x, y)
            CL.galvo_xy = [x y];
        end
        
        function setMode(CL, mode)
            CL.mode = mode;
        end
        
        function frames = getFrames(CL, n)
            frames = zeros(CL.height, CL.width, n);
            for i = 1:n
                frame = CL.getFrame();
                
                % preview frame
                figure(1);
                imagesc(frame);
                drawnow;
                pause(0.05);
                
                frames(:, :, i) = frame;
            end
        end
    end
    
    methods (Access=protected)
        function frame = getFrame(CL)
            % noise background
            frame = rand(CL.height, CL.width) ./ 10;
            
            if strcmp(CL.mode, 'calibrate')
                % make a mesh grid based on the frame dimensions
                [x, y] = meshgrid(1:CL.width, 1:CL.height);
                
                idx = ((x - CL.galvo_xy(1)) .^ 2 + (y - CL.galvo_xy(2)) .^ 2) < 14 .^ 2;
                frame(idx) = 1 - frame(idx);
            else
                error('Simulation mode not supported: %s.', CL.mode);
            end
        end
    end
end

