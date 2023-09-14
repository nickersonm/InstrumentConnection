%% mapSpectrometer.m  MN 2019-03-04
% Maps spectral measurement devices in the lab to their VISA resources 
% and other attributes
% 
% Requirements:
%   - None
% 
% Usage: devStruct = mapSpectrometer(devID)
%   Returns:
%     devStruct: Device information:
%       .ID: string to use as devID
%       .type: string containing the model/manufacturer to select correct SCPI commands
%       .interface: function handle to interface function
%       .visaAddr: string containing the typical VISA connection address
%       .serial: serial number/string
%       .description: string with a description of the device
%
%   Parameters:
%     devID: Device ID; pass 'list' for a cell array of available IDs,
%               'types' for available types
%
% TODO:
%   - 

function devStruct = mapSpectrometer(devID)
%% Validate and initialize
if ~ischar(devID)
    if isnumeric(devID)
        devID = num2str(devID);
    else
        devID = char(devID);
    end
end

meters = cell(0);


%% List of meters
% % Triax320 spectrometer
% devStruct = struct;
% devStruct.ID = 'Triax320';
% devStruct.type = 'triax';
% devStruct.interface = @instSpectrometer_Triax;
% devStruct.visaAddr = '';
% devStruct.serial = '12345';
% devStruct.description = 'PL grating device';
% meters{end+1} = devStruct;

% % IGA3000 CCD array
% devStruct = struct;
% devStruct.ID = 'IGA3000';
% devStruct.type = 'ccd';
% devStruct.interface = @instSpectrometer_Ccd;
% devStruct.visaAddr = '';
% devStruct.serial = '12345';
% devStruct.description = 'InGaAs array on PL';
% meters{end+1} = devStruct;

% Yokogawa AQ6370D
devStruct = struct;
devStruct.ID = 'AQ6370D';
devStruct.type = 'OSA';
devStruct.interface = @instSpectrometer_AQ6370D;
devStruct.visaAddr = 'GPIB2::1::INSTR';
devStruct.serial = '91RB0786';
devStruct.description = 'Yokogawa NIR OSA on cart';
devStruct.span = [600 1700];
devStruct.res = [0.02 0.05 0.1 0.2 0.5 1 2];
devStruct.mode = ["NORM", "MID", "HIGH1", "HIGH2", "HIGH3", "NAUT"];
meters{end+1} = devStruct;


%% Return desired meter
if strcmpi(devID, 'list')
    devStruct = cellfun(@(x) x.ID, meters, 'UniformOutput', 0);
elseif strcmpi(devID, 'types')
    
else
    ii = find(cellfun(@(x) strcmpi(x.ID, devID), meters) | cellfun(@(x) strcmpi(x.serial, devID), meters));

    if ii>0
        devStruct = meters{ii};
    else
        error('Device %s not found!', devID);
    end
end

end
