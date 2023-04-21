%% instDMM_SM2400.m  MN 2020-07-01
% Interface for Keithley SourceMeter 2400 Digital Multimeter
%   https://www.tek.com/datasheet/series-2400-sourcemeter-instruments
%   https://www.tek.com/keithley-source-measure-units/keithley-smu-2400-series-sourcemeter-manual/series-2400-sourcemeter
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: measurement = instDMM_SM2400(visaAddr, option[, value])
%   Returns:
%     measurement: Selected measurement, if requested
%
%   Parameters:
%     visaAddr: Valid VISA address with a DMM connected
%     'option' One of available options below
%     'value' Value for options that require it
%
%     Options:
%       'reset' Resets/initializes power meter to defaults
%       'state', %i: Turns output on or off
%         'on' Same as 'state', 1
%         'off' Same as 'state', 0
%       'current', %f: Sets output current to this if possible (amps)
%       'voltage', %f: Sets output voltage to this if possible (volts)
%       'ilimit', %f: Set output current limit (amps)
%       'vlimit', %f: Set output voltage limit (volts)
%       't', %f: Averages measurements on-device for this long
%       'wires', 2 | 4: Set voltage measurement mode to 2 or 4 wire
%       'outI' Return output current setpoint
%       'outV' Return output voltage setpoint
%       'outlim' Return output limits [Ilim; Vlim]
%       'measI' Returns current measurement (amps)
%       'measV' Returns voltage measurement (volts)
%       'measIV' Returns current and voltage measurement [I; V]
%       'measR' Returns resistance measurement (ohms)
%       'avgt' Return averaging time
%
% TODO:
%   x Decide on default values in 'reset'
%   x Confirm units
%   - Test reading setpoint
%   - Test reading source
%   - Use onboard data store for averaging and statistics instead of longer
%       sampling times?  See manual pg. 171

function measurement = instDMM_SM2400(visaAddr, option, value)
measurement = [];

%% Helper functions
dmmWrite = @(x) visaWrite(visaAddr, x);
dmmQuery = @(x) visaRead(visaAddr, x);
dmmRead = @(x) str2double(dmmQuery(x));

    function dmmChangeMode(cmd, mode)
        if strncmpi(visaRead(visaAddr, sprintf('%s?', cmd)), mode, length(mode)) ~= 1
            visaWrite(visaAddr, sprintf('%s %s', cmd, mode));
        end
    end

dmmOutState = @() str2double(visaRead(visaAddr, 'OUTP?'));


%% Execute selected command
switch lower(option)
    case 'reset'
        % Set standard settings
        dmmWrite('OUTP:ENAB:STAT 0');
        dmmWrite('*RST'); pause(0.5);
        dmmWrite('SYST:AZER 1');  % Auto zero
        dmmWrite('SOUR:VOLT:PROT 40'); % Maximum 40V output
        
        % Standard sense mode: [I, V]
        dmmWrite('SENS:FUNC:CONC 1; :SENS:FUNC "CURR","VOLT"; :FORM ASC; :FORM:ELEM VOLT,CURR');
        
    case {'state', 'on', 'off'}
        % Find the state if not specified
        if ~exist('value', 'var'); value = find(strcmpi(option, {'off', 'on'}),1)-1; end
        % Set state
        switch value > 0
            case 1
                dmmChangeMode('OUTP', '1');
            case 0
                dmmChangeMode('OUTP', '0');
        end
    case 'current'
        % Set output current
        if ~exist('value', 'var'); error('Value not provided for output current!'); end
        
        % Change mode and auto-range
        dmmChangeMode('SOUR:FUNC', 'CURR');
        dmmChangeMode('SOUR:CURR:RANG:AUTO', '1');
        
        % Set output: amps
        dmmWrite(sprintf('SOUR:CURR:LEV %f', double(value)));   % Input in A
    case 'voltage'
        % Set output voltage
        if ~exist('value', 'var'); error('Value not provided for output voltage!'); end
        
        % Change mode and auto-range
        dmmChangeMode('SOUR:FUNC', 'VOLT');
        dmmChangeMode('SOUR:VOLT:RANG:AUTO', '1');
        
        % Set output: volts
        dmmWrite(sprintf('SOUR:VOLT:LEV %f', double(value)));   % Input in volts
    case 'ilimit'
        % Set current output limit
        if ~exist('value', 'var'); error('Value not provided for current limit!'); end
        
        % Requires auto-ohms off
        dmmChangeMode('SENS:RES:MODE', 'MAN');
        
        % Set limit: amps
        dmmWrite(sprintf('SENS:CURR:PROT %f', double(value)));
    case 'vlimit'
        % Set voltage output limit
        if ~exist('value', 'var'); error('Value not provided for voltage limit!'); end
        
        % Requires auto-ohms off
        dmmChangeMode('SENS:RES:MODE', 'MAN');
        
        % Set limit: volts
        dmmWrite(sprintf('SENS:VOLT:PROT %f', double(value)));
    case 'wires'
        % Set 2 or 4 wire measurement mode
        if ~exist('value', 'var'); error('Value not provided for wire measurement mode!'); end
        % Select measurement mode
        switch round(value)
            case 2
                dmmChangeMode('SYST:RSEN', '0');
            case 4
                dmmChangeMode('SYST:RSEN', '1');
            otherwise
                error('Invalid wire number specified: %i', value)
        end
    case 'outi'
        % Retreive output current setpoint
        % Read value: amps
        measurement = dmmRead('SOUR:CURR:LEV?');
    case 'outv'
        % Retreive output voltage setpoint
        % Read value: volts
        measurement = dmmRead('SOUR:VOLT:LEV?');
    case 'outlim'
        % Retreive output [V; I] limits
        % Read value: [amps, volts]
        measurement = [dmmRead('SENS:CURR:PROT:LEV?'); ...
                       dmmRead('SENS:VOLT:PROT:LEV?')];
    case 'measi'
        % Measure output current
        % Only valid if output is enabled
        if ~dmmOutState(); return; end
        
        % Standard sense mode: [V I]
        dmmChangeMode('SENS:FUNC:CONC', '1');
        dmmChangeMode('SENS:FUNC', '"VOLT:DC","CURR:DC"');
        
        % Set auto-ranging
        dmmChangeMode('SENS:CURR:RANG:AUTO', '1');
        
        % Read value: [xxx, amps]
        dmmChangeMode('FORM:ELEM', 'VOLT,CURR');
        measurement = sscanf(dmmQuery('READ?'), '%*f,%f', [1 1]);
    case 'measv'
        % Measure output voltage
        % Only valid if output is enabled
        if ~dmmOutState(); return; end
        
        % Standard sense mode: [V I]
        dmmChangeMode('SENS:FUNC:CONC', '1');
        dmmChangeMode('SENS:FUNC', '"VOLT:DC","CURR:DC"');
        
        % Set auto-ranging
        dmmChangeMode('SENS:VOLT:RANG:AUTO', '1');
        
        % Read value: [volts, xxx]
        dmmChangeMode('FORM:ELEM', 'VOLT,CURR');
        measurement = sscanf(dmmQuery('READ?'), '%f,%*f', [1 1]);
    case 'measiv'
        % Measure output I and V
        % Only valid if output is enabled
        if ~dmmOutState(); return; end
        
        % Fastest to just set rather than query then set
        % Standard sense mode: [V I]
        % Set auto-ranging
        % Read value: [amps, volts]
        setStr = [':SENS:FUNC:CONC 1', ...
            '; :SENS:FUNC "VOLT:DC","CURR:DC"', ...
            '; :SENS:CURR:RANG:AUTO 1; :SENS:VOLT:RANG:AUTO 1', ...
            '; :FORM:ELEM VOLT,CURR']; 
        dmmWrite(setStr);
        
        measurement = sscanf(dmmQuery('READ?'), '%f,%f', [2 1]);
        
        % Swap for return
        measurement = measurement([2, 1]);
    case 'measr'
        % Measure resistance
        % Non-standard sense mode: auto-R
        dmmChangeMode('SENS:FUNC', '"RES"');
        dmmChangeMode('SENS:RES:MODE', 'AUTO');
        dmmChangeMode('SENS:RES:RANG:AUTO', '1');
        
        % Verify output enabled
        dmmChangeMode('OUTP', '1');
        
        % Read value: ohms
        dmmChangeMode('FORM:ELEM', 'RES');
        measurement = dmmRead('READ?');
    case 't'
        % Set on-device averaging time
        % Change mode
        dmmChangeMode('SENS:AVER:TCON', 'REP');    % Bucket, not moving
        
        % Calculate units: speed is one 'power line cycle', or 60Hz
        value = min(100, max(1, round(value * 13.85)));    % Limits 1 .. 100
        
        % Set and enable
        if value > 1
            dmmWrite(sprintf('SENS:AVER:COUN %i; :SENS:AVER 1', value));
        else
            dmmWrite('SENS:AVER:COUN 1; :SENS:AVER 0');
        end
    case 'avgt'
        % Retreive averaging time
        if strncmpi(dmmQuery('SENS:AVER?'), '1', 1) == 1
            % Read value: 'power line cycles', 60Hz
            % Experimentally, only runs at 13.85Hz!
            measurement = dmmRead('SENS:AVER:COUN?');
        else
            measurement = 1;
        end
        
        % Convert to s
        measurement = measurement / 13.85;
    otherwise
        if ~isempty(option)
            error('Unexpected option "%s"', num2str(option));
        end
end


%% Clean up
dmmWrite('SYST:LOCAL');  % Switch back to local mode if possible


end
