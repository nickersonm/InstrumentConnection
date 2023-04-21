%% instDMM_Prototype.m  MN 2020-07-01
% Template for DMM interface
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: measurement = instDMM_Prototype(visaAddr, option[, value])
%   Returns:
%     measurement: Selected measurement, if requested
%
%   Parameters:
%     visaAddr: Valid VISA address with a DMM connected
%     'option': One of available options below
%     'value': Value for options that require it
%
%     Options:
%       'reset': Resets/initializes power meter to defaults
%       'state', %i: Turns output on or off
%         'on': Same as 'state', 1
%         'off': Same as 'state', 0
%       'current', %f: Sets output current to this if possible (amps)
%       'voltage', %f: Sets output voltage to this if possible (volts)
%       'ilimit', %f: Set output current limit (amps)
%       'vlimit', %f: Set output voltage limit (volts)
%       't', %f: Averages measurements on-device for this long
%       'wires', 2 | 4: Set voltage measurement mode to 2 or 4 wire
%       'outI': Return output current setpoint
%       'outV': Return output voltage setpoint
%       'outlim': Return output limits [Ilim; Vlim]
%       'measI': Returns current measurement (amps)
%       'measV': Returns voltage measurement (volts)
%       'measIV': Returns current and voltage measurement [I; V]
%       'measR': Returns resistance measurement (ohms)
%       'avgt': Return averaging time
%
% TODO:
%   - Implement all functions!
%   - Add more options?
%   - Confirm units

function measurement = instDMM_Prototype(visaAddr, option, value)
measurement = [];

%% Helper functions
dmmWrite = @(x) visaWrite(visaAddr, x);
dmmQuery = @(x) str2double(visaRead(visaAddr, x));


%% Execute selected command
switch lower(option)
    case 'reset'
        % Set standard settings
        dmmWrite('*RST'); pause(0.5);
        dmmWrite('*CAL?');  % If available
        dmmWrite('DEFAULT_VALUES');
    case {'state', 'on', 'off'}
        % Find the state if not specified
        if ~exist('value', 'var'); value = find(strcmpi(option, {'off', 'on'}),1)-1; end
        % Set state
        switch value > 0
            case 1
                dmmWrite('COMMAND_ENABLE_OUT');
            case 0
                dmmWrite('COMMAND_DISABLE_OUT');
        end
    case 'current'
        % Set output current
        if ~exist('value', 'var'); error('Value not provided for output current!'); end
        % Switch range if needed
        % Set output: CHECK UNITS
        dmmWrite(sprintf('COMMAND_CURRENT_OUT %f', double(value)));   % Input in A
    case 'voltage'
        % Set output voltage
        if ~exist('value', 'var'); error('Value not provided for output voltage!'); end
        % Switch range if needed
        
        % Set output: CHECK UNITS
        dmmWrite(sprintf('COMMAND_VOLTAGE_OUT %f', double(value)));   % Input in A
    case 'ilimit'
        % Set current output limit
        if ~exist('value', 'var'); error('Value not provided for current limit!'); end
        % Switch range if needed
        
        % Set limit: CHECK UNITS
        dmmWrite(sprintf('COMMAND_I_LIMIT %f', double(value)));
    case 'vlimit'
        % Set voltage output limit
        if ~exist('value', 'var'); error('Value not provided for voltage limit!'); end
        % Switch range if needed
        
        % Set limit: CHECK UNITS
        dmmWrite(sprintf('COMMAND_V_LIMIT %f', double(value)));
    case 't'
        % Set averaging time
        % Calculate units or filters if needed
        dmmWrite(sprintf('COMMAND_AVG_T %f', double(value)));
    case 'wires'
        % Set 2 or 4 wire measurement mode
        if ~exist('value', 'var'); error('Value not provided for wire measurement mode!'); end
        % Select measurement mode
        switch round(value)
            case 2
                dmmWrite('COMMAND_2WIRE');
            case 4
                dmmWrite('COMMAND_4WIRE');
            otherwise
                error('Invalid wire number specified: %i', value)
        end
    case 'outi'
        % Retreive output current setpoint
        % Read value: CHECK UNITS
        measurement = dmmQuery('COMMAND_READ_I_SET');
    case 'outv'
        % Retreive output voltage setpoint
        % Read value: CHECK UNITS
        measurement = dmmQuery('COMMAND_READ_V_SET');
    case 'outlim'
        % Retreive output [I; V] limits
        % Read value: CHECK UNITS
        measurement = [dmmQuery('COMMAND_READ_I_LIM'); ...
                       dmmQuery('COMMAND_READ_V_LIM')];
    case 'measi'
        % Measure output current
        % Read value: CHECK UNITS
        measurement = dmmQuery('COMMAND_READ_I_OUT');
    case 'measv'
        % Measure output voltage
        % Read value: CHECK UNITS
        measurement = dmmQuery('COMMAND_READ_V_OUT');
    case 'measiv'
        % Measure output I and V
        % Read value: CHECK UNITS
        measurement = [dmmQuery('COMMAND_READ_I_OUT'); ...
                       dmmQuery('COMMAND_READ_V_OUT')];
    case 'measr'
        % Measure resistance
        % Read value: CHECK UNITS
        measurement = dmmQuery('COMMAND_READ_R');
    case 'avgt'
        % Retreive averaging time
        % Read value: CHECK UNITS
        measurement = dmmQuery('COMMAND_READ_T_AVG');
        % Calculate units if needed
    otherwise
        if ~isempty(option)
            error('Unexpected option "%s"', num2str(option));
        end
end


%% Clean up
dmmWrite('LOCAL');  % Switch back to local mode if possible


end
