%% mapPM.m  MN 2018-09-19
% Maps available power meters to their VISA resources and other attributes
% 
% Requirements:
%   - None
% 
% Usage: meterStruct = mapPM(meterID)
%   Returns:
%     meterStruct: Power meter information:
%       .ID: string to use as meterID
%       .type:  string containing the model/manufacturer to select correct SCPI commands
%       .interface: function handle to interface function
%       .visaAddr: string containing the typical VISA connection address
%       .serial: serial number/string
%       .minT: minimum usable averaging time, in seconds
%       .powerlim: 1x2 vector containing the min and max power measurable, in watts
%       .wavelim: 1x2 vector containing the min and max wavelength, in nm
%       .description: string with a description of the meter
%
%   Parameters:
%     meterID: Meter ID; pass 'list' for a cell array of available IDs,
%               'types' for available types
%
% TODO:
%   - 

function meterStruct = mapPM(meterID)
%% Validate and initialize
if ~ischar(meterID)
    if isnumeric(meterID)
        meterID = num2str(meterID);
    else
        meterID = char(meterID);
    end
end

meters = cell(0);


%% List of meters
% Sample meter
meterStruct = struct;
meterStruct.ID = 'test';
meterStruct.type = 'ThorLabs PM101';
meterStruct.interface = @instPM_ThorLabsPM101;
meterStruct.visaAddr = '';
meterStruct.serial = '12345';
meterStruct.minT = 0.1;
meterStruct.powerlim = [1e-12 1];
meterStruct.wavelim = [900 1800];
meterStruct.description = 'Small red power meter';
meters{end+1} = meterStruct;

% Next meter
meterStruct = struct;
meterStruct.ID = 'Station2';
meterStruct.type = 'Newport 1830-R';
meterStruct.interface = @instPM_Newport1830;
meterStruct.visaAddr = 'GPIB0::4::INSTR';
meterStruct.serial = '10042';
meterStruct.minT = 0.001;
meterStruct.powerlim = [0 0.1];
meterStruct.wavelim = [800 2000];
meterStruct.description = 'Newport meter at station 2';
meters{end+1} = meterStruct;


%% Return desired meter
if strcmpi(meterID, 'list')
    meterStruct = cellfun(@(x) x.ID, meters, 'UniformOutput', 0);
elseif strcmpi(meterID, 'types')
    
else
    ii = find(cellfun(@(x) strcmpi(x.ID, meterID), meters) | cellfun(@(x) strcmpi(x.serial, meterID), meters));

    if ii>0
        meterStruct = meters{ii};
    else
        error('Meter %s not found!', meterID);
    end
end

end
