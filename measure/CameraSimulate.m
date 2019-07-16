classdef CameraSimulate < Camera
    %CAMERASIMULATE Camera acquisition class to acquire camera images.
    
    properties (Access=protected)
        width = 1024;
        height = 1024;
        
        mode = 'localize-fibers'; % 'calibrate', 'find-fibers', 'localize-fibers'
        
        fibers_xy = [];
        fiber_radius = 14;
        galvo_xy = [0 0];
    end
    
    methods
        function CL = CameraSimulate()
            % create camera class
            CL = CL@Camera();
            
            % generate random fibers
            failures = 25;
            CL.fibers_xy = [];
            while failures > 0
                x = randi([1 + CL.fiber_radius CL.width - CL.fiber_radius], 1);
                y = randi([1 + CL.fiber_radius CL.height - CL.fiber_radius], 1);
                
                % distance to other fibers
                if isempty(CL.fibers_xy)
                    distance = [];
                else
                    distance = sqrt(sum(bsxfun(@minus, CL.fibers_xy, [x y]) .^ 2, 2));
                end
                
                if any(distance < (2 * CL.fiber_radius))
                    failures = failures - 1;
                else
                    CL.fibers_xy = [CL.fibers_xy; x y];
                end
            end
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
                
                % draw laser spot
                idx = ((x - CL.galvo_xy(1)) .^ 2 + (y - CL.galvo_xy(2)) .^ 2) < 14 .^ 2;
                frame(idx) = 1 - frame(idx);
            elseif strcmp(CL.mode, 'find-fibers')
                % make a mesh grid based on the frame dimensions
                [x, y] = meshgrid(1:CL.width, 1:CL.height);
                
                % draw each fiber
                for i = 1:size(CL.fibers_xy, 1)
                    idx = ((x - CL.fibers_xy(i, 1)) .^ 2 + (y - CL.fibers_xy(i, 2)) .^ 2) < CL.fiber_radius .^ 2;
                    frame(idx) = 1 - frame(idx);
                end
            else
                error('Simulation mode not supported: %s.', CL.mode);
            end
        end
    end
end

