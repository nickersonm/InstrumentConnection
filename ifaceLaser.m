%% ifaceLaser.m  MN 2018-09-24
% Sets state, power, and wavelength for a variety of lasers
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected
% 
% Usage: [power, wavelength] = ifaceLaser(laserID, [, option, value])
%   Returns:
%     power: Average power reading in W unless specified
%     powererr: If averaging multiple readings, stdev
%
%   Parameters:
%     laserID: Laser ID - see mapLaser('list') for available power meters
%
%     Options:
%       'state', %i: Turns laser on or off
%       'power', %f: Sets power to this if possible (watts)
%       'wavelength', %f: Sets wavelength to this if possible
%
% TODO:
%   - 

function [power, wavelength] = ifaceLaser(laserID, varargin)
%% Defaults and magic numbers
power = NaN; wavelength = NaN; state = NaN;

inrange = @(x, lims) (x >= min(lims)) & (x <= max(lims));

%% Argument parsing
% Accept a struct.option = value structure
if numel(varargin) > 0 && isstruct(varargin{1})
    paramStruct = varargin{1}; varargin(1) = [];
    varargin = [reshape([fieldnames(paramStruct) struct2cell(paramStruct)]', 1, []), varargin];
end

if mod(numel(varargin),2)   % I always use "'flag', value" even for boolean commands
    error('Odd number of optional inputs!');
end
% Optional alterations
for i = 1:2:length(varargin)
    arg = lower(varargin{i});
    argval = varargin{i+1};
    switch arg
        case 'state'
            state = argval > 0;
        case 'power'
            power = double(argval);
        case 'wavelength'
            wavelength = double(argval);
    end
end


%% Look up power meter and set appropriate interface
laser = mapPM(laserID);

laserInterface = laser.interface;

if isempty(laserInterface)
    error('Unknown laser type "%s" for laser "%s"!', laser.type, laser.ID);
end


%% Set options as requested
if ~isnan(state)
    laserInterface(laser.visaAddr, 'state', state);
end

if ~isnan(power)
    if ~inrange(power, laser.powerlim)
        error('Specified power %.5g out of valid range [%.5g %.5g]!', power, laser.powerlim);
    end
    laserInterface(laser.visaAddr, 'power', state);
end

if ~isnan(wavelength)
    if ~inrange(wavelength, laser.wavelim)
        error('Specified wavelength %.5g out of valid range [%.5g %.5g]!', wavelength, laser.wavelim);
    end
    laserInterface(laser.visaAddr, 'wavelength', wavelength);
end


%% Read current state
[power, wavelength] = laserInterface(laser.visaAddr, 'read');


end
