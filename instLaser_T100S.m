%% instLaser_T100S.m  MN 2018-09-20
% Interface for T100S-HP laser
% https://www.exfo.com/umbraco/surface/file/download/?ni=21587&cn=en-US&pi=17918
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: [power, wavelength] = instLaser_T100S(visaAddr, option[, value])
%   Returns:
%     power: Returns current laser power when requested
%     wavelength: Returns current laser wavelength when requested
%
%   Parameters:
%     visaAddr: Valid VISA address with a ThorLabs power meter connected
%     'option': One of available options below
%     'value': Value for options that require it
%
%     Options:
%       'read' | 'curstate': Retreives present power and wavelength
%       'state', %i: Turns laser on or off
%         'on': Same as 'state', 1
%         'off': Same as 'state', 0
%       'power', %f: Sets power to this if possible (watts)
%       'wavelength', %f: Sets wavelength to this if possible
%
% TODO:
%   - Add more options
%   - Confirm units

function [power, wavelength] = instLaser_T100S(visaAddr, option, value)
power = NaN; wavelength = NaN;

%% Helper functions
lasWrite = @(x) visaWrite(visaAddr, x);
lasQuery = @(x) visaRead(visaAddr, x);


%% Execute selected command
switch lower(option)
    case {'state', 'on', 'off'}
        if ~exist('value', 'var'); value = find(strcmpi(option, {'off', 'on'}),1)-1; end     % Find the state if not specified
        % Set state
        switch value>0
            case 1
                lasWrite('ENABLE');
                lasWrite('APCON');  % Constant-power mode
            case 0
                lasWrite('DISABLE');
        end
    case 'wavelength'
        % Set wavelength
        if ~exist('value', 'var'); error('Value not provided for wavelength!'); end
        lasWrite(sprintf('L=%f', double(value)));
    case 'power'
        % Set power
        if ~exist('value', 'var'); error('Value not provided for power!'); end
        lasWrite('MW');   % Change to mW units
        lasWrite(sprintf('P=%f', double(value)*1e3));   % Input in W
    case {'curstate', 'read'}
        % Return power and wavelength
        power = sscanf(lasQuery('P?'), 'P=%f');
        wavelength = sscanf(lasQuery('L?'), 'L=%f');
end

lasWrite('LOCAL');  % Switch back to local mode


end
