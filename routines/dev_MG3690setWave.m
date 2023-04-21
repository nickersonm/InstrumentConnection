%% dev_MG3690setWave.m  MN 2022-02-17
% Sets the output of an Anritsu MG369X signal generator
% 
% Requirements:
%   - Correct VISA address specified
%   - MG369X connected and addressable
% 
% Usage: state = dev_MG3690setWave(visaAddr, option[, value])
%   Parameters:
%    visaAddr: VISA address to connect to
%     'option' One of available options below
%     'value' Value for options that require it
%
%     Options:
%       'amplitude', %f
%       'freq', %f
%       'on'|'off'
% 
% Returns new state
%
% TODO:

function state = dev_MG3690setWave(visaAddr, varargin)
%% Defaults
amp=NaN; state=NaN; freq=NaN;


%% Helper function
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
        case 'on'
            state = 1;
        case 'off'
            state = 0;
        case {'amp', 'amplitude'}
            amp = double(nextarg('amplitude'));
        case {'freq', 'frequency'}
            freq = double(nextarg('frequency'));
        case {'offset', 'imp', 'z', 'impedance', 'sine'}
            warning('Unsupported option "%s" on MG369X; ignoring.', arg);
            if ~strcmp(arg, 'sine')
                varargin(1) = [];   % Delete following specifier
            end
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


%% SCPI Commands
scpiReset = '*RST';
scpiModOff = ':PM:STAT OFF;:AM:STAT OFF';
scpiOn = ':OUTP:STAT ON';
scpiOff = ':OUTP:STAT OFF';
scpiAmp = @(a) sprintf(':SOUR:POW:LEV:IMM:AMPL %.10g', 10*log10(1e3*a/8/50));   % dBm only, Vpp input
scpiFreq = @(f) sprintf(':SOUR:FREQ:CW %.10g', f);


%% Set options as requested
% Set state if turning off
if state == 0
    visaWrite(visaAddr, scpiModOff);
    visaWrite(visaAddr, scpiOff);
end

% Set amplitude
if ~isnan(amp)
    visaWrite(visaAddr, scpiAmp(amp));
end

% Set frequency
if ~isnan(freq)
    visaWrite(visaAddr, scpiFreq(freq));
end

% Set state if turning on
if state == 1
    visaWrite(visaAddr, scpiModOff);
    visaWrite(visaAddr, scpiOn);
end


end