%% instSpectrometer_AQ6370D.m  MN 2023-09-08
% Interface for AQ6370D OSA
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: measurement = instSpectrometer_AQ6370D(visaAddr, option[, value])
%   Returns:
%     measurement: Selected measurement, if requested
%
%   Parameters:
%     visaAddr: Valid VISA address with a DMM connected
%     'option': One of available options below
%     'value': Value for options that require it
%
%     Options:
%       'reset': Resets/initializes to defaults
%       'span', [%f %f]: Set span
%       'avg', %i: Set trace averaging
%       'res', %f: Set resolution
%       'N', %i: Set number of trace points
%       'mode': Sense mode; valid [NORM, MID, HIGH1, HIGH2, HIGH3]
%       'trig': Trigger new measurement
%       'meas', 0|1: Return new measurement when ready, with (defauult) or without triggering
%
% TODO:
%   - Add more options?
%   - Confirm units

function measurement = instSpectrometer_AQ6370D(visaAddr, option, value)
measurement = [];

%% Helper functions
specWrite = @(x) visaWrite(visaAddr, x);
specQuery = @(x) str2double(visaRead(visaAddr, x));


%% Execute selected command
switch lower(option)
    case 'reset'
        % Set standard settings
        specWrite('*RST'); pause(0.5);
        specWrite('*CLS');
        specWrite(':FORM:DATA REAL,64; :SENS:WAV:STAR 900nm; :SENS:WAV:STOP 1400nm; :SENS:SWE:POIN 501');
    case 'span'
        if ~exist('value', 'var'); error('Value not provided for span!'); end
        if numel(value) < 2; error('Insufficient elements provided for span!'); end
        
        % Set measurement span
        specWrite(sprintf(':SENS:WAV:STAR %gnm; :SENS:WAV:STOP %gnm', double(value)));
    case 'res'
        if ~exist('value', 'var'); error('Value not provided for averaging count!'); end
        % Set resolution
        specWrite(sprintf(':SENS:BAND %fnm', double(value)));
    case 'avg'
        if ~exist('value', 'var'); error('Value not provided for resolution!'); end
        % Set averaging count
        specWrite(sprintf(':SENS:AVER:COUN %i', round(value)));
    case 'n'
        % Set measurement points
        if ~exist('value', 'var'); error('Value not provided for measurement points!'); end
        specWrite(sprintf(':SENS:SWE:POIN %i', round(value)));
    case 'mode'
        % Set measurement mode
        if ~exist('value', 'var'); error('Value not provided for measurement mode!'); end
        specWrite(sprintf(':SENS:SENS %s', value));
    case 'trig'
        % Trigger new measurement
        specWrite(':ABOR; *CLS; :INIT:IMM'); measurement = NaN;
    case 'meas'
        % Set data format
        specWrite(':FORM:DATA REAL,64; :TRAC:ACT TRA');
        
        % Trigger unless specified otherwise
        if exist('value', 'var') && value > 0; specWrite(':ABOR; :INIT:SMOD SING; :INIT:IMM'); end
        
        % Wait for sweep complete
        i = 0;
        while ~(specQuery(':STAT:OPER:COND?') & 1)
            fprintf('.'); i = i+1;
            pause(0.5);
            if i>3; fprintf(repmat(sprintf('\b'), [1 i])); i = 0; end
        end
        fprintf(repmat(sprintf('\b'), [1 i]));
        
        % Retrieve spectrum
        visaObj = visaConn(visaAddr);
        flushinput(visaObj); flushoutput(visaObj);
        specWrite(':TRAC:X? TRA');
        L = readbinblock(visaObj, 'double');
        specWrite(':TRAC:Y? TRA');
        P = readbinblock(visaObj, 'double');
        measurement = [L(:), P(:)];
        
        % Resume continuous measurements for user
        specWrite(':INIT:SMOD REP; :INIT:IMM');
    otherwise
        if ~isempty(option)
            error('Unexpected option "%s"', num2str(option));
        end
end


%% Clean up


end
