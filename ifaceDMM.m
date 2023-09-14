%% ifaceDMM.m  MN 2020-07-01
% Sets state and output parameters for a variety of digital multimeters and source meters
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected
% 
% Usage: [[I; V], measurement, std] = ifaceDMM(dmmID[, option, value])
%   Returns:
%     I: Actual output current; NaN if output off
%     V: Actual output voltage; NaN if output off
%     measurement: Selected additional measurement, if requested
%     std: Standard deviation of I, V, measurement, if averaging enabled
%
%   Parameters:
%     dmmID: DMM ID - see mapDMM('list') for available DMMs
%
%     Options:
%       'state', %i: Turns DMM output on or off
%         'on': Same as 'state', 1
%         'off': Same as 'state', 0
%       'reset': Resets/initializes DMM to standard values
%       'current' | 'i', %f: Change to current mode and set output to this current (amps)
%       'voltage' | 'v', %f: Change to voltage mode and set output to this voltage (volts)
%       'getout': Return presently set output, measurement = [Iout; Vout]
%       'limit', [%f, %f]: Sets output current and voltage limits (amps, volts)
%       'ilimit', %f: Set output current limit (amps)
%       'vlimit', %f: Set output voltage limit (volts)
%       'getlim': Return output limits, measurement = [Ilim; Vlim]
%       'w' | 'wires' | 'measmode', 2 | 4: Select between 2 or 4 wire measurement mode
%           Will turn output off
%       't' | 'avg', %f: Average measurements this long
%       'rmeas' | 'r': Measure resistance; will turn output on
%
% TODO:
%   - Verify units
%   - Test and debug
%   - Check wire-mode logic
%   - Shut off before changing wire-measurement mode?

function [IV, measurement, stdIVM] = ifaceDMM(dmmID, varargin)
%% Defaults and magic numbers
avgT = NaN; outI = NaN; outV = NaN; limit = [NaN, NaN]; reset = 0; state = NaN; wires = NaN;
meas = NaN;


%% Helper functions
    inrange = @(x, lims) (x >= min(lims)) & (x <= max(lims));
    
    function arg = nextarg(strExpected)
        if isempty(strExpected); strExpected = ''; end
        if ~isempty(varargin)
            arg = varargin{1}; varargin(1) = [];
        else
            error('Expected next argument "%s", but no more arguments present!', strExpected);
        end
    end


%% Argument parsing
% Accept a struct.option = value structure
if numel(varargin) > 0 && isstruct(varargin{1})
    paramStruct = varargin{1}; varargin(1) = [];
    varargin = [reshape([fieldnames(paramStruct) struct2cell(paramStruct)]', 1, []), varargin];
end

% Parameter parsing
while ~isempty(varargin)
    arg = lower(varargin{1}); varargin(1) = [];
    
    switch arg
        case 'reset'
            reset = 1;
        case 'state'
            state = nextarg('state') > 0;
        case 'on'
            state = 1;
        case 'off'
            state = 0;
        case {'current', 'i'}
            outI = double(nextarg('output current'));
        case {'voltage', 'v'}
            outV = double(nextarg('output voltage'));
        case 'limit'
            limit = double(nextarg('[I, V] limits'));
            if numel(limit) < 2
                warning('"limit" was passed with only one value, assuming current limit %f', limit(1));
                limit = [limit(1) NaN];
            end
            meas = 'lim';
        case 'ilimit'
            limit(1) = double(nextarg('current limit'));
        case 'vlimit'
            limit(2) = double(nextarg('voltage limit'));
        case {'w', 'wires', 'measmode'}
            wires = round(nextarg('measurement mode (2 or 4)'));
            wires = find([2 4] == wires, 1)*2;   % 2 or 4 only!
        case {'t', 'avg'}
            avgT = double(nextarg('averaging time'));
        case {'meas', 'rmeas', 'r'}
            meas = 'R';
        case {'getout', 'out', 'output', 'getoutput'}
            meas = 'out';
        case {'getlim', 'lim', 'getlimit'}
            meas = 'lim';
        otherwise
            if ~isempty(arg)
                warning('Unexpected option "%s"', num2str(arg));
                if ~strcmpi(input('Continue? [y/N]: ', 's'), 'y')
                    disp('Aborted.');
                    return;
                end
            end
    end
end


%% Dependent parameters or defaults


%% Look up power meter and set appropriate interface
DMM = mapDMM(dmmID);

dmmInterface = DMM.interface;

if isempty(dmmInterface)
    error('Unsupported DMM type "%s" for DMM "%s"!', DMM.type, dmmID);
end


%% Set options as requested
% Turn off
if ~isnan(state) && state == 0
    dmmInterface(DMM.visaAddr, 'state', state);
    pause(0.25); % Wait for update
end

% Reset/initialize
if reset == 1
    dmmInterface(DMM.visaAddr, 'reset');
    pause(0.5); % Wait for reset
end

% Change measurement mode
if ~isnan(wires)
    dmmInterface(DMM.visaAddr, 'wires', wires);
end

% Set output current limit
if ~isnan(limit(1))
    if ~inrange(limit(1), DMM.currentlim)
        error('Specified limit current %.5g out of valid range [%.5g %.5g]!', limit(1), DMM.currentlim(1), DMM.currentlim(2));
    end
    dmmInterface(DMM.visaAddr, 'ilimit', limit(1));
end

% Set output voltage limit
if ~isnan(limit(2))
    if ~inrange(limit(2), DMM.voltagelim)
        error('Specified compliance voltage limit %.5g out of valid range [%.5g %.5g]!', limit(2), DMM.voltagelim);
    end
    dmmInterface(DMM.visaAddr, 'vlimit', limit(2));
end

% Set on-device averaging time
if ~isnan(avgT)
    % Set on-device averaging?
    dmmInterface(DMM.visaAddr, 't', min([avgT DMM.maxtime]) );
else
    avgT = 0;   % No local averaging
end

% Set output current
if ~isnan(outI)
    if ~inrange(outI, DMM.currentlim)
        error('Specified current %.5g out of valid range [%.5g %.5g]!', outI, DMM.currentlim(1), DMM.currentlim(2));
    end
    dmmInterface(DMM.visaAddr, 'current', outI);
    pause(0.1); % Wait for update
end

% Set output voltage
if ~isnan(outV)
    if ~inrange(outV, DMM.voltagelim)
        error('Specified voltage %.5g out of valid range [%.5g %.5g]!', outV, DMM.voltagelim(1), DMM.voltagelim(2));
    end
    dmmInterface(DMM.visaAddr, 'voltage', outV);
    pause(0.1); % Wait for update
end

% Turn on
if ~isnan(state) && state == 1
    dmmInterface(DMM.visaAddr, 'state', state);
    pause(0.25); % Wait for update
end


%% Take measurements
% Helper function to simplify
function [I, V, M] = measAll(meas)
    M = dmmInterface(DMM.visaAddr, 'measIV');
    if numel(M) > 1
        I = M(1); V = M(2);
    else
        I = NaN; V = NaN;
    end
    
    switch meas
        case 'R'
            M = dmmInterface(DMM.visaAddr, 'measR');
        case 'out'
            M = [dmmInterface(DMM.visaAddr, 'outI'); dmmInterface(DMM.visaAddr, 'outV')];
        case 'lim'
            M = dmmInterface(DMM.visaAddr, 'outlim');
        otherwise
            M = NaN;
    end
end

% First measurement
tic;
[I, V, measurement] = measAll(meas);

% Average if requested
while toc < avgT
    [I(end+1), V(end+1), measurement(:, end+1)] = measAll(meas);
end
stdIVM = std([I; V; measurement], 0, 2);
IV = mean([I; V], 2); measurement = mean(measurement, 2);


end
