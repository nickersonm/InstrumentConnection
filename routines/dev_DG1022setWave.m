%% dev_DG1022setWave.m  MN 2022-01-07
% Sets the output of a Rigol DG1022 signal generator
% 
% Requirements:
%   - Correct VISA address in defaults section or specified
%   - DG1022 connected and addressable
% 
% Usage: state = dev_DG1022setWave(visaAddr, ch, option[, value])
%   Parameters:
%    ch: Which channel to control
%    visaAddr: VISA address to connect to
%     'option' One of available options below
%     'value' Value for options that require it
%
%     Options:
%       'amplitude', %f
%       'offset', %f
%       'freq', %f
%       'sine'|'ramp'|'square'|'dc'
%       'imp'|'impedance', 50|'inf'|NaN
%       'on'|'off'
% 
% Returns new state
%
% TODO:
%   - Migrate to proper InstrumentConnection interface

function state = dev_DG1022setWave(visaAddr, ch, varargin)
%% Defaults
ch = round(ch);
amp=NaN; offset=NaN; wave=NaN; Z=NaN; state=NaN; freq=NaN;


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
        case 'offset'
            offset = double(nextarg('offset voltage'));
        case {'freq', 'frequency'}
            freq = double(nextarg('frequency'));
        case 'sine'
            wave = 'SIN';
        case 'ramp'
            wave = 'RAMP';
        case 'square'
            wave = 'SQU';
        case 'dc'
            wave = 'DC';
        case {'imp', 'z', 'impedance'}
            Z = nextarg('impedance');
            if strcmp(Z, 'inf') || isnan(Z) || isinf(Z)
                Z = 'INF';
            elseif Z > 0
                Z = '50';
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
if strcmp(ch, 2); ch = ':CH2'; else; ch = ''; end

scpiOn = sprintf('OUTP%s ON', ch);
scpiOff = sprintf('OUTP%s OFF', ch);
scpiAmp = @(a) sprintf('VOLT%s %.10g', ch, a);
scpiFreq = @(f) sprintf('FREQ%s %.10g', ch, f);
scpiOffset = @(o) sprintf('VOLT:OFFS%s %.8g', ch, o);
scpiWave = @(w) sprintf('FUNC%s %s', ch, w);
scpiImp = @(l) sprintf('OUT:LOAD%s %s', ch, l);


%% Set options as requested
% Set state if turning off
if state == 0
    visaWrite(visaAddr, scpiOff);
end

% Set wave
if ~isnan(wave)
    visaWrite(visaAddr, scpiWave(wave));
end

% Set amplitude
if ~isnan(amp)
    visaWrite(visaAddr, scpiAmp(amp));
end

% Set offset
if ~isnan(offset)
    visaWrite(visaAddr, scpiOffset(offset));
end

% Set frequency
if ~isnan(freq)
    visaWrite(visaAddr, scpiFreq(freq));
end

% Set impedance
if ~isnan(Z)
    visaWrite(visaAddr, scpiImp(Z));
end

% Set state if turning on
if state == 1
    visaWrite(visaAddr, scpiOn);
end


end