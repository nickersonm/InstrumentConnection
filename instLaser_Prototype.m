%% instLaser_Prototype.m  MN 2018-09-20
% Template for laser interface
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: [power, wavelength] = instLaser_Prototype(visaAddr, option[, value])
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

function [power, wavelength] = instLaser_Prototype(visaAddr, option, value)
power = NaN; wavelength = NaN;

%% Helper functions
lasWrite = @(x) visaWrite(visaAddr, x);
lasQuery = @(x) str2num(visaRead(visaAddr, x));


%% Execute selected command
switch lower(option)
    case {'state', 'on', 'off'}
        % Change state
        if ~exist('value', 'var'); value = find(strcmpi(option, {'off', 'on'}),1)-1; end     % Find the state
    case 'wavelength'
        % Set wavelength
        if ~exist('value', 'var'); error('Value not provided for wavelength!'); end
    case 'power'
        % Set power
    case {'curstate', 'read'}
        % Return power and wavelength
end



end
