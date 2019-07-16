classdef ManualSteer < handle
    %MANUALSTEER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        range = 10;
        
        sg;
        
        % window
        win;
        axes;
        
        h;
    end
    
    methods
        function obj = ManualSteer(sg, range)
            %MANUALSTEER Construct an instance of this class
            %   Detailed explanation goes here
            obj.sg = sg;
            
            obj.win = figure;
            obj.win.Units = 'pixels';
            obj.win.WindowButtonDownFcn = {@obj.cb_clickWindow};
            obj.win.DeleteFcn = {@obj.cb_closeWindow};
            
            if exist('range', 'var') && ~isempty(range)
                obj.range = range;
            end
            
            obj.axes = axes('Parent', obj.win);
            xlim(obj.axes, [-1 1] .* obj.range);
            ylim(obj.axes, [-1 1] .* obj.range);
        end
        
        function delete(obj)
            try
                delete(obj.win);
            catch err %#ok<NASGU>
            end
        end
        
        function cb_clickWindow(obj, h, event)
            % get position
            pos = get(obj.axes, 'CurrentPoint');
            
            % make sure there is a value
            if size(pos, 1) < 1
                return;
            end
            
            % not an open click
            if ~strcmp(h.SelectionType, 'open')
                return;
            end
            
            % get position
            x = pos(1, 1); y = pos(1, 2);
            
            % check range
            if abs(x) > obj.range || abs(y) > obj.range
                warning('Coordinates out of range: %f, %f', x, y);
                return;
            end
            
            disp([x y]);
            
            if ~isempty(obj.h)
                delete(obj.h);
            end
            
            % draw it
            hold(obj.axes, 'on');
            obj.h = plot(obj.axes, x, y, '.b', 'MarkerSize', 14);
            hold(obj.axes, 'off');
            
            % set it
            obj.sg.debugPoint(x, y);
        end
        
        function cb_closeWindow(obj, h, event)
        end
    end
end

