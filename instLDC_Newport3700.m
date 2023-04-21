%% instLDC_Newport3700.m  MN 2020-06-26
% Interface for Newport LDC-3700 series laser diode controllers
% https://www.newport.com/medias/sys_master/images/images/h0b/hfa/8797190848542/LDC-37x4C-User-Manual.pdf
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: [current, voltage, temperature] = instLDC_Newport3700(visaAddr, option[, value])
%   Returns:
%     current: Returns diode output current
%     voltage: Returns diode output voltage
%     temperautre: Returns TEC temperature reading
%
%   Parameters:
%     visaAddr: Valid VISA address with a diode controller connected
%     'option': One of available options below
%     'value': Value for options that require it
%
%     Options:
%       'reset': Resets/initializes LDC
%       'read' | 'curstate' | 'measure': Returns present [I, V, T]
%       'state', %i: Turns diode output on or off
%         'on': Same as 'state', 1
%         'off': Same as 'state', 0
%       'current', %f: Sets output current to this if possible (amps)
%       'limit', [%f, %f]: Sets diode output current and voltage limits (amps, volts)
%       'set', %f: Changes TEC temperature setpoint to this; <0 for 'off'
%
% TODO:
%   - Add more options
%   - Confirm units

function [current, voltage, temperature] = instLDC_Newport3700(visaAddr, option, value)

%% Helper functions
ldcWrite = @(x) visaWrite(visaAddr, x);
ldcQuery = @(x) str2double(visaRead(visaAddr, x));


%% Defaults and magic numbers
current = NaN; voltage = NaN; temperature = NaN;


%% Execute selected command
switch lower(option)
    case 'reset'
        % Set standard settings
        ldcWrite('LAS:OUT 0;LAS:LIM:V 5;LAS:LDI 15e-3');
        ldcWrite('TEC:OUT 0;TEC:MODE:T;TEC:T 20');
        ldcWrite('*CAL?;TEC:OUT 1');
    case {'state', 'on', 'off'}
        if ~exist('value', 'var'); value = find(strcmpi(option, {'off', 'on'}),1)-1; end     % Find the state if not specified
        % Set mode if needed
        if ~strncmpi(visaRead(visaAddr, 'LAS:MODE?'), 'ILBW', 4)
            ldcWrite('LAS:MODE:ILBW');  % Constant-current mode
        end
        % Set state
        switch value>0
            case 1
                ldcWrite('LAS:OUT 1');
            case 0
                ldcWrite('LAS:OUT 0');
        end
        ldcWrite('LAS:DIS:LDI');   % Change display to actual output current
    case {'read', 'curstate', 'measure'}
        % Read the current output values
        current = ldcQuery('LAS:LDI?')*1e-3;   % Return A
        voltage = ldcQuery('LAS:LDV?');
        temperature = ldcQuery('TEC:T?');
    case 'current'
        % Set diode output current
        if ~exist('value', 'var'); error('Value not provided for diode current!'); end
        % This model has two ranges: 200mA and 500mA
        if value <= 0.2
            ldcWrite('LAS:RAN 2');
        else
            ldcWrite('LAS:RAN 5');
        end
        ldcWrite(sprintf('LAS:LDI %f', double(value*1e3)));   % Input in A
    case 'limit'
        % Set diode current and voltage limits
        if ~exist('value', 'var'); error('Value not provided for diode output limits!'); end
        % This model has two ranges: 200mA and 500mA - set same range for both
        ldcWrite(sprintf('LAS:LIM:I2 %f', double(value(1)*1e3)));   % Input in A
        ldcWrite(sprintf('LAS:LIM:I5 %f', double(value(1)*1e3)));   % Input in A
        % Switch to appropriate range
        if value(1) <= 0.2
            ldcWrite('LAS:RAN 2');
        else
            ldcWrite('LAS:RAN 5');
        end
        % Set compliance limit for some models
        if length(value) > 1
            ldcWrite(sprintf('LAS:LIM:V %f', double(value(2))));
        end
    case 'set'
        % Set TEC temperature
        if ~exist('value', 'var'); error('Value not provided for TEC setpoint!'); end
        ldcWrite('TEC:OUT 0;TEC:MODE:T');
        if value >= 0
            ldcWrite(sprintf('TEC:T %f', double(value)));
            if (ldcQuery('TEC:SET:T?') - value) < 1e-2   % Setpoint mismatch
                ldcWrite('TEC:OUT 1');
            else
                error('Attempted to set temperature to %f, but inconsistent values: aborting!', value);
            end
        end
end


%% Clean up
% ldcWrite('LOCAL');  % No way to switch back to local mode on these models


end
