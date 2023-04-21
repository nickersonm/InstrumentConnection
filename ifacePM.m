%% ifacePM.m  MN 2018-09-19
% Retrieves power measurement for a variety of IPL's power meters
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected
% 
% Usage: [power, powererr] = ifacePM(meterID[, option, value])
%   Returns:
%     power: Average power reading in W unless specified
%     powererr: If averaging multiple readings, stdev
%
%   Parameters:
%     meterID: Meter ID - see mapPM('list') for available power meters
%
%     Options:
%       'units', ('W' | 'dBm'): Default W; convert to dBm if specified
%       'wavelength', %f: Set meter to this wavelength; nm
%       't' | 'avg', %f: Average this long
%       'softavg', 1: Use software averaging only
%       'reset', 1: Reset power meter first
%
% TODO:
%   - 

function [power, powererr] = ifacePM(meterID, varargin)
%% Defaults and magic numbers
unitdBm = 0;
reset = 0;
avgT = NaN;
wavelength = NaN;
softavg = 0;

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
        case 'softavg'
            softavg = double(argval);
        case 'wavelength'
            wavelength = double(argval);
        case 'reset'
            reset = argval > 0;
        case 'units'
            unitdBm = strcmpi(argval, 'dBm');
        otherwise
            error('Unexpected flag "%s"', arg);
    end
end


%% Look up power meter and set appropriate interface
meter = mapPM(meterID);

pmInterface = meter.interface;

if isempty(pmInterface)
    error('Unsupported power meter type "%s" for meter "%s"!', meter.type, meterID);
end

% Update timeout if needed
meterConn = visaConn(meter.visaAddr);
if meterConn.Timeout > 0.5
    meterConn.Timeout = 0.5;
end


%% Set options as requested
if reset == 1
    pmInterface(meter.visaAddr, 'reset');
    pmInterface(meter.visaAddr, 't', meter.minT);
end

if ~isnan(avgT)
    if softavg > 0
        meterT = meter.minT;
    elseif avgT < meter.minT
%         fprintf('Specified averaging time %.5g is lower than minimum %.5g, setting to minumum\n', avgT, meter.minT);
        meterT = meter.minT;
    else
        meterT = avgT;
    end
    pmInterface(meter.visaAddr, 't', meterT);
end

if ~isnan(wavelength)
    if ~inrange(wavelength, meter.wavelim)
        error('Specified wavelength %.5g out of valid range [%.5g %.5g]!', wavelength, meter.wavelim);
    end
    pmInterface(meter.visaAddr, 'wavelength', wavelength);
end


%% Measure
if avgT > 0
    meterT = pmInterface(meter.visaAddr, 't?');
    power = NaN(1, max(1, ceil(avgT/meterT)));
else
    power = NaN;
end

for ii = 1:numel(power)
    try     % Deal with timeouts
        power(ii) = pmInterface(meter.visaAddr, 'measure');
    catch exc
        if contains(exc.message, 'Timeout')
            pause(1e-2);
            power(ii) = pmInterface(meter.visaAddr, 'measure');
        else
            rethrow(exc);
        end
    end
end
power = reshape(power,1,[]);    % Some meters return many measurements

powererr = std(power);
power = nanmean(power);

% Check range validity
if ~inrange(power, meter.powerlim)
    warning('INST:PM:RangeError', 'Measured power %.5g out of valid range [%.5g %.5g] - use with caution', power, meter.powerlim(1), meter.powerlim(2));
end

% Convert if desired
if unitdBm == 1
    power = log10(power)*10;
    powererr = log10(powererr)*10;
end

end
