%% mapPiezo.m  MN 2020-08-17
% Maps available piezo controllers to their VISA resources and other attributes
% 
% Requirements:
%   - None
% 
% Usage: piezoStruct = mapPiezo(piezoID)
%   Returns:
%     piezoStruct: Laser information:
%       .ID: string to use as piezoID
%       .type:  string containing the model/manufacturer to select correct SCPI commands
%       .interface: function handle to interface function
%       .visaAddr: string containing the typical VISA connection address
%       .serial: serial number/string
%       .channels: cell of output channels
%       .description: string with a description of the laser
%
%   Parameters:
%     piezoID: Piezo ID; pass 'list' for a cell array of available IDs,
%               'types' for available types
%
% TODO:
%   - 

function piezoStruct = mapPiezo(piezoID)
%% Validate and initialize
if ~ischar(piezoID)
    if isnumeric(piezoID)
        piezoID = num2str(piezoID);
    else
        piezoID = char(piezoID);
    end
end

piezos = cell(0);


%% List of Piezos
% Lower piezo controller on Station2 measurement setup
piezoStruct = struct;
piezoStruct.ID = 'Station2left';
piezoStruct.type = 'MDT693B';
piezoStruct.interface = @instPiezo_MDT693;
piezoStruct.visaAddr = 'ASRL3::INSTR';
piezoStruct.serial = 'Station2left';
piezoStruct.channels = {'x', 'y', 'z'};
piezoStruct.description = 'Thorlabs 3-channel piezo controller';
piezos{end+1} = piezoStruct;

% Upper piezo controller on Station2 measurement setup
piezoStruct = struct;
piezoStruct.ID = 'Station2right';
piezoStruct.type = 'MDT693B';
piezoStruct.interface = @instPiezo_MDT693;
piezoStruct.visaAddr = 'ASRL5::INSTR';
piezoStruct.serial = 'MDT693B';
piezoStruct.channels = {'x', 'y', 'z'};
piezoStruct.description = 'Thorlabs 3-channel piezo controller';
piezos{end+1} = piezoStruct;


%% Return desired Piezo
if strcmpi(piezoID, 'list')
    piezoStruct = cellfun(@(x) x.ID, piezos, 'UniformOutput', 0);
elseif strcmpi(piezoID, 'types')
    
else
    ii = find(cellfun(@(x) strcmpi(x.ID, piezoID), piezos) | cellfun(@(x) strcmpi(x.serial, piezoID), piezos));

    if ii>0
        piezoStruct = piezos{ii};
    else
        error('Piezo %s not found!', piezoID);
    end
end

end
