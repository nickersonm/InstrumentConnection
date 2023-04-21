%% ifaceLDC.m  MN 2020-06-26
% Sets state and output parameters for a variety of laser diode controllers
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected
% 
% Usage: [[I; V; T], [stdI; stdV; stdT]] = ifaceLDC(ldcID[, option, value])
%   Returns:
%     I: Diode output current
%     V: Diode output voltage
%     T: TEC temperature reading
%     std<I,V,T>: Standard deviation of above, if averaging requested
%
%   Parameters:
%     ldcID: LDC ID - see mapLDC('list') for available LDCs
%
%     Options:
%       'state', %i: Turns diode output on or off
%       'current', %f: Sets output current to this if possible (amps)
%       'limit', [%f, %f]: Sets diode output current and voltage limits (amps, volts)
%       'temperature' | 'temp', %f: Changes TEC temperature setpoint to this; <0 for 'off'
%       't' | 'avg', %f: Average measurements this long
%       'reset', 1: Resets/initializes LDC to standard values first
%
% TODO:
%   - Verify units
%   - Test and debug

function [IVT, stdIVT] = ifaceLDC(ldcID, varargin)
%% Defaults and magic numbers
I=[]; V=[]; T=[];
avgT = 0; outI = NaN; limit = NaN; temp = NaN; reset = 0; state = NaN;

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
        case {'t', 'avg'}
            avgT = double(argval);
        case 'state'
            state = argval > 0;
        case 'current'
            outI = double(argval);
        case 'limit'
            limit = double(argval);
        case {'temperature', 'temp'}
            temp = double(argval);
        case 'reset'
            reset = argval > 0;
    end
end


%% Look up power meter and set appropriate interface
ldc = mapLDC(ldcID);

ldcInterface = ldc.interface;

if isempty(ldcInterface)
    error('Unsupported LDC type "%s" for LDC "%s"!', ldc.type, ldcID);
end


%% Set options as requested
if reset == 1
    ldcInterface(ldc.visaAddr, 'reset');
    pause(0.5); % Wait for reset
end

if ~isnan(temp)
    ldcInterface(ldc.visaAddr, 'set', temp);
end

if ~isnan(limit)
    if ~inrange(limit(1), ldc.currentlim)
        error('Specified limit current %.5g out of valid range [%.5g %.5g]!', limit(1), ldc.currentlim);
    end
    if length(limit) > 1
        if ~inrange(limit(2), ldc.voltagelim)
            error('Specified compliance voltage limit %.5g out of valid range [%.5g %.5g]!', limit(2), ldc.voltagelim);
        end
    end
    ldcInterface(ldc.visaAddr, 'limit', limit);
end

if ~isnan(outI)
    if ~inrange(outI, ldc.currentlim)
        error('Specified current %.5g out of valid range [%.5g %.5g]!', outI, ldc.currentlim);
    end
    ldcInterface(ldc.visaAddr, 'current', outI);
    pause(0.1); % Wait for update
end

if ~isnan(state)
    ldcInterface(ldc.visaAddr, 'state', state);
    pause(0.5); % Wait for update
end


%% Read present state, with averaging if enabled
tic;
[I, V, T] = ldcInterface(ldc.visaAddr, 'read');
while toc < avgT
    [I(end+1), V(end+1), T(end+1)] = ldcInterface(ldc.visaAddr, 'read');
end
IVT = mean([I; V; T], 2);
stdIVT = std([I; V; T], 0, 2);


end
