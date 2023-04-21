%% instPM_Prototype.m  MN 2018-09-20
% Template for power meter interface
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: [retval] = instPM_Prototype(visaAddr, option[, value])
%   Returns:
%     retval: If option == 'measure', returns power reading
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

function retval = instPM_Prototype(visaAddr, option, value)
retval = NaN;

%% Helper functions
pmWrite = @(x) visaWrite(visaAddr, x);
pmQuery = @(x) str2num(visaRead(visaAddr, x));


%% Execute selected command
switch lower(option)
    case 'reset'
        % Reset meter and wait until done
    case 't'
        % Set averaging time
        if ~exist('value', 'var'); error('Value not provided for averagint time!'); end
    case 'wavelength'
        % Set wavelength
        if ~exist('value', 'var'); error('Value not provided for wavelength!'); end
    case 'measure'
        % Measure power
end


end
