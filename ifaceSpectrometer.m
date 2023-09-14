%% ifaceSpectrometer.m  MN 2023-09-08
% Interface with spectrometers
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected
% 
% Usage: [[L, P], measurement] = ifaceSpectrometer(specID[, option, value])
%   Returns:
%     L: Measured wavelength
%     P: Measured power
%     measurement: Selected additional measurement, if requested
%
%   Parameters:
%     specID: Spectrometer ID - see mapSpec('list') for available spectrometers
%
%     Options:
%       'reset': Reset/initialize to standard values
%       'span' | 'range', [%f, %f]: Set range/span [nm]
%       'mode', %i: Set mode; varies by spectrometer
%       'res' | 'resolution', %f: Set resolution [nm]
%       'avg', %i: Set averaging number
%       'points' | 'N', %i: Set number of points
%       'notrig': Don't trigger new measurement
%       'nomeas': Don't return measurement
%
% TODO:
%   - Verify units
%   - Test and debug

function [LP, measurement] = ifaceSpectrometer(specID, varargin)
%% Defaults and magic numbers
avg = NaN; span = [NaN, NaN]; reset = 0; mode = ""; trig = 1; N = NaN; res = NaN; meas = 1;


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
        case 'notrig'
            trig = 0;
        case {'nomeas', 'skip'}
            meas = 0;
        case {'range', 'span'}
            span = double(nextarg('wavelength span'));
            if numel(span) < 2
                warning('"span" was passed with only one value, assuming current span %f', span(1));
                span = [span(1) NaN];
            end
        case 'avg'
            avg = round(nextarg('# traces for averaging'));
        case 'mode'
            mode = upper(string(nextarg('measurement mode')));
        case {'res', 'resolution'}
            res = nextarg('resolution');
        case {'points', 'N'}
            N = round(nextarg('# points'));
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
span = sort(span);


%% Look up power meter and set appropriate interface
spec = mapSpectrometer(specID);

specInterface = spec.interface;

if isempty(specInterface)
    error('Unsupported spectrometer type "%s" for spectrometer "%s"!', spec.type, dmmID);
end


%% Set options as requested
% Reset/initialize
if reset == 1
    specInterface(spec.visaAddr, 'reset');
end

% Set span
if ~isnan(span(1))
    if ~inrange(span(1), spec.span)
        error('Specified span start %.5g out of valid range [%.5g %.5g]!', span(1), spec.span(1), spec.span(2));
    end
    if ~inrange(span(2), spec.span)
        error('Specified span end %.5g out of valid range [%.5g %.5g]!', span(2), spec.span(1), spec.span(2));
    end
    specInterface(spec.visaAddr, 'span', span);
end

% Set resolution
if ~isnan(res)
    res = spec.res(find(spec.res-res<=0, 1, 'last'));
    specInterface(spec.visaAddr, 'res', res );
end

% Set points
if ~isnan(N)
    specInterface(spec.visaAddr, 'N', max([round(N) 101]) );
end

% Set measurement mode
if strlength(string(mode)) > 0
    if ~ismember(mode, spec.mode)
        error('Specified mode "%s" is invalid; available modes "[%s]"!', mode, strjoin(spec.mode, ","));
    end
    specInterface(spec.visaAddr, 'mode', mode );
end

% Set trace averaging
if ~isnan(avg)
    specInterface(spec.visaAddr, 'avg', max([round(avg) 1]) );
end


%% Take measurements
if meas < 1 && trig > 1
    specInterface(spec.visaAddr, 'trig');
end
if meas > 0
    LP = specInterface(spec.visaAddr, 'meas', trig);
else
    LP = [NaN NaN];
end

end
