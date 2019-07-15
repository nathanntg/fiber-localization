classdef FiberEditor < handle
    %FIBEREDITOR Tool to edit fiber annotations
    
    properties
        default_radius = 10;
        
        % only populated on close
        centers;
        radii;
    end
    
    properties (Access=protected)
        % image
        image
        
        % annotations
        annotations = {}; % rows: points, columns: x, y, type
        
        % handles
        win
        axes
    end
    
    methods
        function CL = FiberEditor(image, centers, radii)
            CL.image = image;
            
            % create viewer window
            CL.win = figure();
            
            % set 
            set(CL.win, 'Units', 'pixels');
            set(CL.win, 'WindowButtonDownFcn', {@CL.cb_clickWindow});
            set(CL.win, 'DeleteFcn', {@CL.cb_closeWindow});
            
            % get axes
            CL.axes = axes('Parent', CL.win);
            
            % show image
            imshow(CL.image, 'Parent', CL.axes, 'Border', 'tight');
            pan off;

            % initial values
            if exist('centers', 'var') && exist('radii', 'var')
                for i = 1:size(centers, 1)
                    % add to annotations
                    CL.annotations{end + 1} = drawcircle(CL.axes, 'Center', centers(i, :), 'Radius', radii(i), 'StripeColor', 'red');
                end
            end
        end
        
        function delete(CL)
            try
                delete(CL.win);
            catch err %#ok<NASGU>
            end
        end
        
        function cb_clickWindow(CL, h, event)
            % imgca(AN.win)
            pos = get(CL.axes, 'CurrentPoint');
            
            % make sure there is a value
            if size(pos, 1) < 1
                return;
            end
            
            i = pos(1, 1); j = pos(1, 2);
            
            % add to annotations
            if strcmp(h.SelectionType, 'open')
                CL.addAnnotation(i, j);
            end
        end
        
        function cb_closeWindow(CL, h, event)
            [CL.centers, CL.radii] = CL.getAnnotations();
            
            % nothing to do
            if ~isvalid(CL)
                return;
            end
            
            % clear image
            clear CL.image;
        end
        
        function [centers, radii] = getAnnotations(CL)
            idx = cellfun(@(x) isvalid(x), CL.annotations);
            
            centers = cellfun(@(x) x.Center, CL.annotations(idx), 'UniformOutput', false);
            centers = cat(1, centers{:});
            
            radii = cellfun(@(x) x.Radius, CL.annotations(idx));
            radii = radii(:)';
        end
        
        function [centers, radii] = waitForAnnotations(CL)
            waitfor(CL.axes);
            centers = CL.centers;
            radii = CL.radii;
        end
    end
    
    methods (Access=protected)
        function addAnnotation(CL, i, j)
            % add to annotations
            CL.annotations{end + 1} = drawcircle(CL.axes, 'Center', [i j], 'Radius', CL.default_radius, 'StripeColor', 'red');
        end
    end
end
