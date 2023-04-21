%% instPM_ThorLabsPM101.m  MN 2018-09-19
% Single-command interfaces for ThorLabs power meters
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: [power] = instPM_ThorLabsPM101(visaAddr, option[, value])
%   Returns:
%     power: If option == 'measure', returns power reading
%
%   Parameters:
%     visaAddr: Valid VISA address with a ThorLabs power meter connected
%     'option': One of available options below
%     'value': Value for options that require it
%
%     Options:
%       'reset': Resets/initializes power meter
%       't', %f: Sets measurement time to this
%       't?':   Retreive measurement time
%       'measure': Measures one reading and returns value
%       'wavelength', %f: Sets wavelength to this if necessary
%
% TODO:
%   - Add more options
%   - Confirm units

function power = instPM_ThorLabsPM101(visaAddr, option, value)
power = NaN;

%% Helper functions
pmWrite = @(x) visaWrite(visaAddr, x);
pmQuery = @(x) str2double(visaRead(visaAddr, x));


%% Execute selected command
switch lower(option)
    case 'reset'
        % Reset meter and wait until done
        pmWrite('*RST');
        while pmQuery('*OPC') ~= 1; pause(0.01); end
        pmWrite('CONF');
        pmWrite('INIT');
    case 't'
        if ~exist('value', 'var'); error('Value not provided for averagint time!'); end
        pmWrite(sprintf('AVER %i', ceil(value/3e-6))); % 3ms per sample according to manual
    case 't?'
        power = ifacePM('AVER?')*3e-6;   % 3ms per sample
    case 'wavelength'
        if ~exist('value', 'var'); error('Value not provided for wavelength!'); end
        if pmQuery('CORR:WAV?') ~= value
            pmWrite(sprintf('CORR:WAV %f', value));
        end
    case 'measure'
        power = pmQuery('READ?');
end


end
