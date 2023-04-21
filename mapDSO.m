%% mapDSO.m  MN 2020-07-14
% Maps available digital oscilloscopes to their VISA resources and other attributes
% 
% Requirements:
%   - None
% 
% Usage: dsoStruct = mapDSO(dsoID)
%   Returns:
%     dsoStruct: Laser information:
%       .ID: string to use as dsoID
%       .type:  string containing the model/manufacturer to select correct SCPI commands
%       .interface: function handle to interface function
%       .visaAddr: string containing the typical VISA connection address
%       .serial: serial number/string
%       .bandwidth: maximum bandwidth in Hz
%       .channels: number of input channels
%       .description: string with a description of the laser
%
%   Parameters:
%     dsoID: DSO ID; pass 'list' for a cell array of available IDs,
%               'types' for available types
%
% TODO:
%   - 

function dsoStruct = mapDSO(dsoID)
%% Validate and initialize
if ~ischar(dsoID)
    if isnumeric(dsoID)
        dsoID = num2str(dsoID);
    else
        dsoID = char(dsoID);
    end
end

dsos = cell(0);


%% List of DSOs
% DSO on Station 2 setup
% USB connection is about 2.5x faster
dsoStruct = struct;
dsoStruct.ID = 'Station2USB';
dsoStruct.type = 'DSO6104A';
dsoStruct.interface = @instDSO_A6000;
dsoStruct.visaAddr = 'USB0::0x0957::0x1754::MY44003501::0::INSTR';
dsoStruct.serial = '44003501';
dsoStruct.bandwidth = 1e9;
dsoStruct.channels = 4;
dsoStruct.description = 'Agilent 4ch 1GHz DSO, USB connection';
dsos{end+1} = dsoStruct;

% Same DSO, but via GPIB
dsoStruct.ID = 'Station2GPIB';
dsoStruct.visaAddr = 'GPIB0::7::INSTR';
dsoStruct.description = 'Agilent 4ch 1GHz DSO, GPIB connection';
dsos{end+1} = dsoStruct;


%% Return desired DSO
if strcmpi(dsoID, 'list')
    dsoStruct = cellfun(@(x) x.ID, dsos, 'UniformOutput', 0);
elseif strcmpi(dsoID, 'types')
    
else
    ii = find(cellfun(@(x) strcmpi(x.ID, dsoID), dsos) | cellfun(@(x) strcmpi(x.serial, dsoID), dsos));

    if ii>0
        dsoStruct = dsos{ii};
    else
        error('DSO %s not found!', dsoID);
    end
end

end
