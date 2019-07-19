classdef Fibers < handle
    %FIBERS Handles fiber identification and extraction from frames
    
    properties
        default_radius;
        
        overlap_fraction = 0.85;
        mask_fraction = 0.7;
    end
    
    properties (Access=protected)
        im;
        
        centers;
        radii;
        
        masks;
    end
    
    methods
        function CL = Fibers()
        end
        
        function findFibersViaCamera(CL, camera)
            % print guidance
            fprintf('** FIBER IDENTIFICATION **\n');
            fprintf('To most easily identify fibers, illuminate the fiber cores using a\n');
            fprintf('wavelength visible via the emission filter (e.g., white light). The\n');
            fprintf('fiber centers can be discovered using a circle finding algorithm.\n');
            fprintf('You will have a chance to review and manually add/remove fibers after\n');
            fprintf('automatic detection. Press any key to continue.\n');
            pause;
            
            % get images
            images = camera.getFrames(10);
            
            % average images
            images_mean = mean(images, ndims(images));
            if ~ismatrix(images_mean) && size(images_mean, 3) > 1
                % convert to grayscale (may not be right, not sure
                % colorspace representation returned by image acquisition)
                warning('Assuming image is RGB colorspace.');
                images_mean = rgb2gray(images_mean);
            end
            
            % adjust image
            images_mean = imadjust(mat2gray(images_mean));
            
            CL.findFibersViaImage(images_mean);
        end
            
        function findFibersViaImage(CL, images_mean)
            % save image
            CL.im = images_mean;
            
            % STEP 1: automatic detection
            if isempty(CL.default_radius)
                % annotate one image
                fe = FiberEditor(images_mean);
                title('Annotate one fiber');
                fe.default_radius = 25;
                [~, radius] = fe.waitForAnnotations();
                
                radius_range = [0.7 1.3] .* mean(radius);
            else
                radius_range = [0.7 1.3] .* CL.default_radius;
            end
            
            % need integer range
            radius_range(1) = floor(radius_range(1));
            radius_range(2) = ceil(radius_range(2));
            
            for sensitivity = linspace(0.8, 0.97, 20)
                [cur_centers, cur_radii] = imfindcircles(images_mean, radius_range, 'ObjectPolarity', 'bright', 'Sensitivity', sensitivity);
                
                if CL.isFeasibleFibers(cur_centers, cur_radii) || isempty(CL.centers)
                    CL.centers = cur_centers;
                    CL.radii = cur_radii;
                else
                    break;
                end
            end
            
            % STEP 2: manual review
            fprintf('Manually review the identified fibers. Add or remove fibers as needed.\n');
            fprintf('Close the window to continue.\n');
            
            fe = FiberEditor(images_mean, CL.centers, CL.radii);
            fe.default_radius = mean(radius_range);
            [CL.centers, CL.radii] = fe.waitForAnnotations();
            
            % STEP 3: make masks
            CL.makeMasks();
        end
        
        function [centers, radii] = getFibers(CL)
            centers = CL.centers;
            radii = CL.radii;
        end
        
        function intensity = extractIntensity(CL, frame)
            intensity = zeros(size(CL.centers, 1), 1);
            for i = 1:size(CL.centers, 1)
                intensity(i) = mean(frame(CL.masks{i}));
            end
        end
    end
    
    methods (Access=protected)
        function s = isFeasibleFibers(CL, centers, radii)
            % actual distance between pairs of fibers
            dist_actual = squareform(pdist(centers));
            
            % clear diagonal
            dist_actual(logical(eye(size(dist_actual)))) = inf;
            
            % minimum distance to not overlap
            dist_min = CL.overlap_fraction .* (radii + radii');
            
            % no overlaps?
            s = ~any(dist_actual(:) < dist_min(:));
        end
        
        function makeMasks(CL)
            % make a mesh grid based on the frame dimensions
            [x, y] = meshgrid(1:size(CL.im, 2), 1:size(CL.im, 1));
            
            % make masks
            CL.masks = cell(1, size(CL.centers, 1));
            for i = 1:size(CL.centers, 1)
                CL.masks{i} = find(((x - CL.centers(i, 1)) .^ 2 + (y - CL.centers(i, 2)) .^ 2) < ((CL.mask_fraction * CL.radii(i)) .^ 2));
            end
        end
    end
end

