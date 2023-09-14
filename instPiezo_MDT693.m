%% instPiezo_Prototype.m  MN 2020-06-26
% Piezo controller interface for ThorLabs MDT693 3-channel controller
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected on specified VISA address
% 
% Usage: meas = instPiezo_Prototype(visaAddr, option[, value])
%   Returns:
%     meas: Returns results of command
%
%   Parameters:
%     visaAddr: Valid VISA address with a diode controller connected
%     'option': One of available options below
%     'value': Value for options that require it
%
%     Options:
%       'read' | 'measure', %i: Returns voltage of channel %i
%       'readall' | 'all', %i: Read all available channels
%       'set' | 'v', %i, %f: Sets channel %i to voltage %f
%       'setall', %f: Set all available channels to voltage %f
%           If multiple channels, accepts %f as array
%       'limit' | 'maxv': Returns system maximum voltage
%       'serial': Returns device serial
%
% TODO:
%   - Add more options

function meas = instPiezo_MDT693(visaAddr, option, varargin)

%% Helper functions
% TODO: replace with `serialport`
piezoWrite = @(x) visaWrite(visaAddr, x);
piezoRead = @(x) replace(visaRead(visaAddr, x), {'>', char([13 13])}, '');


%% Defaults and magic numbers
chs = 'xyz';    % For MDT693B


%% Set appropriate properties for this abnormal type of connection
visaObj = visaConn(visaAddr);
visaObj.BaudRate = 115200;
visaObj.FlowControl = 'none';
visaObj.Parity = 'none';
configureTerminator(visaObj, 'CR');
if (~contains(visaObj.Status, 'open')) || ...
        (visaObj.InputBufferSize < 4096)
    visaObj.InputBufferSize = 4096;
    fopen(visaObj);
end


%% Execute selected command
switch lower(option)
    case 'serial'
        % Get serial
        meas = piezoRead('friendly?');
    case {'limit', 'maxv'}
        % Get and format voltage limit
        meas = str2num(piezoRead('vlimit?'));
    case {'read', 'measure'}
        if isempty(varargin); error('Value not provided for channel!'); end
        if round(varargin{1}) > length(chs); error('Specified channel %i exceeds available channels (%i)', varargin{1}, length(chs)); end
        % Get and format channel voltage
        meas = str2num( piezoRead(sprintf('%cvoltage?', chs(round(varargin{1})))) );
    case {'readall', 'all'}
        % MDT693B modern firmware actually has a 'xyzvoltage' command
        meas = str2num( piezoRead(sprintf('%svoltage?', chs)) );
    case {'set', 'v'}
        if size(varargin) < 2; error('Insufficient parameters to set voltage: only %i provided', numel(varargin)); end
        if round(varargin{1}) > length(chs); error('Specified channel %i exceeds available channels (%i)', varargin{1}, length(chs)); end
        % Set channel voltage
        piezoWrite( sprintf('%cvoltage=%.2f', chs(round(varargin{1})), double(varargin{2}) ) );
        meas = str2num( piezoRead(sprintf('%cvoltage?', chs(round(varargin{1})))) );
    case {'setall', 'vall'}
        if (numel(varargin{1}) > 1) && (numel(varargin{1}) ~= length(chs))
            warning('Voltage array %s does not match number of channels (%i); trimming to first entry (%f).', num2str(varargin{1}, '%f,'), length(chs), varargin{1}(1));
            varargin{1} = double(varargin{1}(1));
        end
        % Build voltage to correct size
        if numel(varargin{1}) ~= numel(chs)
            varargin{1} = varargin{1}(1)*ones(size(chs));
        end
        % Set channel voltage
        outQ = sprintf('%svoltage=%s', chs, num2str(varargin{1}, '%.2f,'));
        piezoWrite( outQ(1:end-1) );
        meas = str2num( piezoRead( sprintf('%svoltage?', chs) ) );
end


%% Clean up


end
