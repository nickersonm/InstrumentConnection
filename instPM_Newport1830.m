%% instPM_Newport1830.m  MN 2018-09-20
% Single-command interfaces for Newport 1830-series power meters
% https://www.newport.com/medias/sys_master/images/images/h5c/hb2/8796988604446/1830-R-Manual-RevA.pdf
% Similar to 1936-type, but lacking in some features, notably the datastore
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: [retval] = instPM_Newport1830(visaAddr, option[, value])
%   Returns:
%     retval: If option == 'measure', returns power reading
%
%   Parameters:
%     visaAddr: Valid VISA address with a Newport power meter connected
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
%   - Figure out averaging times

function retval = instPM_Newport1830(visaAddr, option, value)
retval = [];
sampleTime = 1e-3;
filters = [16 4 1];    % Available digital filters per the manual

%% Helper functions
pmWrite = @(x) visaWrite(visaAddr, x);
pmQuery = @(x) str2double(visaRead(visaAddr, x));


%% Execute selected command
switch lower(option)
    case 'reset'
        % Set standard settings
        pmWrite('*RST');
        pmWrite('L0;A0;U1;F3;R0;G1'); % No local-lockout, W, no filter, auto-range
    case 't'
        % Set approximate filtering - no longer in seconds; undefined
        if ~exist('value', 'var'); error('Value not provided for averagint time!'); end
        pmWrite(sprintf('F%i', max(1, find(value >= filters*sampleTime, 1))));
    case 't?'
        retval = filters(pmQuery('F?'))*sampleTime;
    case 'wavelength'
        if ~exist('value', 'var'); error('Value not provided for wavelength!'); end
        if pmQuery('W?') ~= value
            pmWrite(sprintf('W%f', value));
        end
    case 'measure'
        retval = pmQuery('D?');
end
pause(0.005);


end
