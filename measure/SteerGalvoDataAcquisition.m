classdef SteerGalvoDataAcquisition < SteerGalvo
    %STEERGALVODATAACQUISITION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=protected)
        vendor;
        device_name;
        channels = [0 1];
        mode = 'Voltage';
        
        session;
    end
    
    methods
        function CL = SteerGalvoDataAcquisition(vendor, device_name, channels, mode)
            %STEERGALVODATAACQUISITION Construct an instance of this class
            %   Detailed explanation goes here
            
            % call parent
            CL@SteerGalvo();
            
            % store vendor
            CL.vendor = vendor;
            CL.device_name = device_name;
            if exist('channels', 'var') && ~isempty(channels)
                assert(length(channels) == 2);
                CL.channels = channels;
            end
            if exist('mode', 'var') && ~isempty(mode)
                CL.mode = mode;
            end
        end
        
        % USEFUL DURING CALIBRATION, remove later
        function debug(CL, ch1, ch2)
            % start if needed
            if ~CL.started
                CL.startDevice();
                CL.started = true;
            end
            
            % set values
            CL.setValues(ch1, ch2);
        end
    end
    
    
    methods (Access=protected)
        function startDevice(CL)
            CL.session = daq.createSession(CL.vendor);
            addAnalogOutputChannel(CL.session, CL.device_name, CL.channels, CL.mode);
            
            % run in foreground
            startForeground(CL.session);
        end
        
        function stopDevice(CL)
            release(CL.session);
        end
        
        function setValues(CL, ch1, ch2)
            outputSingleScan(CL.session, [ch1 ch2]);
        end
    end
end

