%% dev_DSOgetTrace.m  MN 2018-07-18
% Captures the current trace data from a Keysight DSO6000-series DSO
% 
% Requirements:
%   - Correct VISA address in defaults section or specified
%   - DSO6000 connected and addressable
% 
% Usage: [Y, X] = dev_DSOgetTrace(ch, visaAddr)
%   Parameters:
%    ch: Which channel to retreive
%    visaAddr: VISA address to connect to
% 
% Returns:
%    Y: Voltage data
%    X: Time data
%
% TODO:
%   - 

function [Y, X] = dev_DSOgetTrace(chs, visaAddr, doQuick, N)
%% Defaults
chs = round(chs);

if ~exist('N', 'var') || ~isnumeric(N) || N<500
    N = 1e9;
end


%% Helper function
    function visaWait()
        while str2double(visaRead(visaAddr, scpiComplete)) ~= 1
            pause(0.05);
        end
    end


%% SCPI Commands
% DSO6000-series SCPI commands
% scpiSetAvg = sprintf(':TRAC:TYPE AVER;:AVER:COUN %i', avgN);
% scpiNewTrace = ':AVER:CLE;:INIT';
scpiComplete = '*OPC?';

scpiRunning = @() (bitand(str2double(visaRead(visaAddr, 'OPER:COND?')), bitset(0, 4)) > 0);
scpiStop = ':ACQ:MODE RTIM; :STOP; :SING; *WAI';
scpiRun = ':RUN';
scpiPrepare = @(N) sprintf('WAV:FORM BYTE; UNS 1; POIN %i; POIN:MODE MAX; *WAI', N);
scpiChan = @(ch) sprintf('WAV:SOUR CHAN%i; *WAI', ch);
scpiGetData = '*WAI; :WAV:DATA?';
scpiGetPreable = '*WAI; :WAV:PRE?';


%% Initialize
% Verify stopped: must be stopped to record max points
if ~exist('doQuick', 'var') || doQuick ~= 1
    if scpiRunning()
        runMode = 1;
        visaWrite(visaAddr, scpiStop); pause(0.05);
    else
        runMode = 0;
    end
else
    runMode = 1;
end

Y = [];
for ch = chs(:)'
    % Select channel
    visaWrite(visaAddr, scpiChan(ch));

    % Set format
    visaWrite(visaAddr, scpiPrepare(N));

    % Get preamble
    preamble = NaN;
    while any(isnan(preamble))
        preamble = str2double(split(visaRead(visaAddr, scpiGetPreable), ','));
    end
    byteCount = preamble(1)+1;
    N = preamble(3);
    dX = preamble(5);
    xOff = preamble(6);
    xRef = preamble(7);
    dY = preamble(8);
    yOff = preamble(9);
    yRef = preamble(10);


    %% Initialize VISA object for large transfer
    visaObj = visaConn(visaAddr);
    if visaObj.InputBufferSize < N
        fclose(visaObj);
        visaObj.InputBufferSize = 2^nextpow2(N);
        fopen(visaObj); flushinput(visaObj);
    end


    %% Read data
    % Read Y-data
    flushinput(visaObj);  visaWrite(visaAddr, scpiGetData);
    Yi = binblockread(visaObj, sprintf('uint%i', 8*byteCount) );

    % Scale Y-data
    Yi = (Yi(:) - yRef) * dY + yOff;
    
    Y = [Y, Yi];

end

% Calculate X-data using last channel's preamble
X = ((0:(N-1) - xRef)' * dX + xOff);


%% Return to running if was running
if runMode == 1
    visaWrite(visaAddr, scpiRun);
end

end