classdef SteerGalvoDataAcquisition < SteerGalvo
    %STEERGALVODATAACQUISITION Use MATLAB DAQ session to control galvo
    %   Incldues helpful debugging functions.
    
    properties (Access=protected)
        vendor;
        device_name;
        channels = [0 1];
        mode = 'Voltage';
        
        session;
    end
    
    methods (Static)
        function CL = selectGalvo()
            fprintf('** SELECT DATA ACQUISITION DEVICE **\n');
            
            % step 1: device
            fprintf('Which device would you like to use?\n\n');
            info = daq.getDevices();
            for i = 1:length(info)
                fprintf('%d. %s\n', i, info(i).Description);
            end
            fprintf('\n');
            device_idx = input('Device: ');
            vendor_id = info(device_idx).Vendor.ID;
            device_id = info(device_idx).ID;
            
            fprintf('Defaulting to channels 0 and 1, voltage control.\n');
            
            % create steering device
            CL = SteerGalvoDataAcquisition(vendor_id, device_id);
        end
    end
    
    methods
        function CL = SteerGalvoDataAcquisition(vendor, device_name, channels, mode)
            %STEERGALVODATAACQUISITION Construct an instance of this class
            %   Detailed explanation goes here
            
            % call parent
            CL = CL@SteerGalvo();
            
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
        
        % debugging functions, useful for calibration
        
        function debugLine(CL, ch, rng, repeat, steps)
            % ch: which channel (1 or 2, required)
            % rng: range to move along channel (default full range)
            % repeat: times to repeat (default 10)
            % steps: steps to complete line (default 500)
            %        time depends on the frequency of the DAQ device
            
            % start if needed
            if ~CL.started
                CL.startDevice();
                CL.started = true;
            end
            
            if ch ~= 1 && ch ~= 2
                error('Invalid channel, specify either 1 or 2.');
            end
            
            % get range
            if ~exist('rng', 'var') || isempty(rng)
                if ch == 1
                    rng = CL.ch1_range;
                elseif ch == 2
                    rng = CL.ch2_range;
                end
            elseif isscalar(rng)
                rng = rng .* [-1 1];
            end
            if (ch == 1 && (rng(1) < CL.ch1_range(1) || rng(2) > CL.ch2_range(2))) || (ch == 2 && (rng(1) < CL.ch2_range(1) || rng(2) > CL.ch2_range(2)))
                error('Range out of bounds.');
            end
            
            % repeat default
            if ~exist('repeat', 'var') || isempty(repeat)
                repeat = 10;
            end
            
            % steps
            if ~exist('steps', 'var') || isempty(steps)
                steps = 500;
            end
            
            % make values
            if ch == 1
                ch1 = linspace(rng(1), rng(2), steps);
                ch2 = zeros(size(ch1));
            elseif ch == 2
                ch2 = linspace(rng(1), rng(2), steps);
                ch1 = zeros(size(ch2));
            end
            
            % run
            for i = 1:repeat
                queueOutputData(CL.session, [ch1' ch2']);
                CL.session.startForeground();
            end
        end
        
        function debugSquare(CL, rng1, rng2, repeat, steps)
            % rng1: range to move along channel 1 (default full range)
            % rng2: range to move along channel 2 (default full range)
            % repeat: times to repeat (default 10)
            % steps: steps to complete one edge of the square (default 500)
            %        time depends on the frequency of the DAQ device
            
            % start if needed
            if ~CL.started
                CL.startDevice();
                CL.started = true;
            end
            
            % get range
            if ~exist('rng1', 'var') || isempty(rng1)
                rng1 = CL.ch1_range;
            elseif isscalar(rng1)
                rng1 = rng1 .* [-1 1];
            end
            if ~exist('rng2', 'var') || isempty(rng2)
                rng2 = CL.ch2_range;
            elseif isscalar(rng1)
                rng2 = rng2 .* [-1 1];
            end
            if rng1(1) < CL.ch1_range(1) || rng1(2) > CL.ch2_range(2) || rng2(1) < CL.ch2_range(1) || rng2(2) > CL.ch2_range(2)
                error('Range out of bounds.');
            end
            
            % repeat default
            if ~exist('repeat', 'var') || isempty(repeat)
                repeat = 10;
            end
            
            % steps
            if ~exist('steps', 'var') || isempty(steps)
                steps = 500;
            end
            
            % make values
            ch1_asc = linspace(rng1(1), rng1(2), steps);
            ch1_desc = ch1_asc(end:-1:1);
            ch2_asc = linspace(rng2(1), rng2(2), steps);
            ch2_desc = ch2_asc(end:-1:1);
            
            ch1 = [ch1_asc rng1(2) .* ones(size(ch2_asc)) ch1_desc rng1(1) .* ones(size(ch2_desc))];
            ch2 = [rng2(1) .* ones(size(ch1_asc)) ch2_asc rng2(2) .* ones(size(ch1_desc)) ch2_desc];
            
            % run
            for i = 1:repeat
                CL.session.queueOutputData([ch1' ch2']);
                CL.session.startForeground();
            end
        end
    end
    
    methods (Access=protected)
        function startDevice(CL)
            CL.session = daq.createSession(CL.vendor);
            addAnalogOutputChannel(CL.session, CL.device_name, CL.channels, CL.mode);
        end
        
        function stopDevice(CL)
            release(CL.session);
        end
        
        function setValues(CL, ch1, ch2)
            outputSingleScan(CL.session, [ch1 ch2]);
        end
    end
end

