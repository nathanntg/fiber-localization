classdef Fibers < handle
    %FIBERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        default_radius;
    end
    
    properties (Access=protected)
        im;
        
        centers;
        radii;
    end
    
    methods
        function CL = Fibers()
        end
        
        function findFibers(CL, camera)
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
            
            % save image
            CL.im = images_mean;
            
            % STEP 1: automatic detection
            if isempty(CL.default_radius)
                % binarize
                images_bin = imbinarize(images_mean);
                
                % get axis length as guess of radii
                properties = regionprops(images_bin, 'MajorAxisLength', 'MinorAxisLength');
                
                % concatenate axis lengths, average major / minor, and
                % convert from diameter to radius
                potential_radii = mean([cat(1, properties(:).MajorAxisLength) cat(1, properties(:).MinorAxisLength)], 2) ./ 2;
                
                radius_range = [0.7 1.3] .* median(potential_radii);
            else
                radius_range = [0.7 1.3] .* CL.default_radius;
            end
            
            for sensitivity = linspace(0.85, 0.97, 20)
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
        end
        
        function [centers, radii] = getFibers(CL)
            centers = CL.centers;
            radii = CL.radii;
        end
        
        function intensity = extractIntensity(CL, frame)
            
        end
    end
    
    methods (Access=protected)
        function s = isFeasibleFibers(CL, centers, radii)
            % actual distance between pairs of fibers
            dist_actual = squareform(pdist(centers));
            
            % clear diagonal
            dist_actual(logical(eye(size(dist_actual)))) = inf;
            
            % minimum distance to not overlap
            dist_min = radii + radii';
            
            % no overlaps?
            s = any(dist_actual(:) < dist_min(:));
        end
    end
end

