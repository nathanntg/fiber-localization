classdef FindFibers
    %FINDFIBERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        default_radius;
        
        centers;
        radiuses;
    end
    
    properties (Access=protected)
        im;
    end
    
    methods
        function CL = FindFibers()
            %FINDFIBERS Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

