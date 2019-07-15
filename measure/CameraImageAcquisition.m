classdef CameraImageAcquisition < Camera
    %CAMERAIMAGEACQUISITION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        vi
    end
    
    methods (Static)
        function CL = selectCamera()
            fprintf('** SELECT CAMERA **\n');
            
            % step 1: adaptor
            fprintf('Which video adaptor would you like to use? If you do not see the\n');
            fprintf('expected adaptor, install the required MATLAB add-in.\n\n');
            info = imaqhwinfo;
            for i = 1:length(info.InstalledAdaptors)
                fprintf('%d. %s\n', i, info.InstalledAdaptors{i});
            end
            fprintf('\n');
            adaptor_idx = input('Adaptor: ');
            adaptor = info.InstalledAdaptors{adaptor_idx};
            
            % step 2: device
            fprintf('Which video device would you like to use?\n\n');
            info = imaqhwinfo(adaptor);
            for i = 1:length(info.DeviceInfo)
                fprintf('%d. %s\n', i, info.DeviceInfo(i).DeviceName);
            end
            fprintf('\n');
            device_idx = input('Device: ');
            device_id = info.DeviceIDs{device_idx};
            device = info.DeviceInfo(device_idx);
            
            % step 3. format (optional)
            if 1 == length(device.SupportedFormats)
                CL = CameraImageAcquisition(adaptor, device_id);
            else
                fprintf('Which video format would you like to use?\n\n');
                for i = 1:length(device.SupportedFormats)
                    fprintf('%d. %s\n', i, device.SupportedFormats{i});
                end
                fprintf('\n');
                format_idx = input('Format: ');
                format = device.SupportedFormats{format_idx};
                
                CL = CameraImageAcquisition(adaptor, device_id, format);
            end
            
            % configure
            CL.configure();
        end
    end
    
    methods
        function CL = CameraImageAcquisition(varargin)
            %CAMERAIMAGEACQUISITION Construct an instance of this class
            %   Arguments: adapter, device_id_or_name, format, properties
            
            % create camera class
            CL = CL@Camera();
            
            % create video object
            CL.vi = videoinput(varargin{:});
            
            % preview
            preview(CL.vi);
        end
        
        function configure(CL)
            vs = getselectedsource(CL.vi);
            
            % TODO: write configuration process
        end
        
        function delete(CL)
            % close preview
            if strcmp(CL.vi.Previewing, 'on')
                closepreview(CL.vi);
            end
            
            % clear video acquisition
            delete(CL.vi);
        end
        
        function frames = getFrames(CL, n)
            % frames per trigger
            CL.vi.FramesPerTrigger = n;
            
            % start video input
            start(CL.vi);
            
            % get frames
            frames = getdata(CL.vi, n);
        end
    end
end

