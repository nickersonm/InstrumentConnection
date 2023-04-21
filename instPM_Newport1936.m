%% instPM_Newport1936.m  MN 2018-09-19
% Single-command interfaces for Newport 1936-series power meters
% https://www.newport.com/medias/sys_master/images/images/h7c/h54/9123359326238/90039770B-1936-2936-R-Power-Meter-User-s-Manual.pdf
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: [retval] = instPM_Newport1936(visaAddr, option[, value])
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
%   - Confirm averaging time read

function retval = instPM_Newport1936(visaAddr, option, value)
retval = [];

%% Helper functions
pmWrite = @(x) visaWrite(visaAddr, x);
pmQuery = @(x) str2double(visaRead(visaAddr, x));


%% Execute selected command
switch lower(option)
    case 'reset'
        % Set standard settings
        pmWrite('PM:ATT 0;PM:MODE 0;PM:UNIT 2;PM:DS:UNIT 2;PM:FILT 0'); % CW, W, no filter
        pmWrite('PM:DS:BUF 1;PM:DS:INT 1;PM:DS:SIZE 2e3');  % Enable buffer with 2e3*0.1ms = 0.2s size
    case 't'
        % Set analog filtering and intermittent datastore
        if ~exist('value', 'var'); error('Value not provided for averagint time!'); end
        filters = [1e6 250e3 12.5e3 1e3 5];    % Available analog filters per the manual
        filters = max(0, find(1/t >= filters, 1)-2);
        int = max(1, floor(1e4*value)); % Interval to sample at; every-Nth at 10kHz
        pmWrite(sprintf('PM:ANALOGFILTER %i;PM:DS:INT %i', filters, int));
    case 't?'
        retval = ifacePM('PM:ANALOGFILTER?')*ifacePM('PM:DS:INT?');    % TODO: verify/fix
    case 'wavelength'
        if ~exist('value', 'var'); error('Value not provided for wavelength!'); end
        if pmQuery('PM:L?') ~= value
            pmWrite(sprintf('PM:L %f', value));
        end
    case 'measure'
        pmWrite('PM:DS:CL;PM:DS:EN 1'); % Clear buffer and enable
        N = pmQuery('PM:DS:INT?');  % Check to see if this is a reduced sample rate
        nC = pmQuery('PM:DS:C?');
        while numel(retval) < 1000/N || numel(retval) < nC    % Collect until we have it all, at least 1k
            nC = pmQuery('PM:DS:C?'); ii = numel(retval)+1;
            if ii < nC  % Collect if anything is available
                retval = [retval reshape(pmQuery(sprintf('PM:DS:GET? %i-%i', ii, max(ii+10, nC)))  ,1,[])];
            else
                pause(0.001*N);   % Wait if there is no new data available
            end
        end
end


end
