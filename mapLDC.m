%% mapLDC.m  MN 2020-06-26
% Maps available LDCs to their VISA resources and other attributes
% 
% Requirements:
%   - None
% 
% Usage: ldcStruct = mapLDC(ldcID)
%   Returns:
%     ldcStruct: LDC information:
%       .ID: string to use as ldcID
%       .type:  string containing the model/manufacturer to select correct SCPI commands
%       .interface: function handle to interface function
%       .visaAddr: string containing the typical VISA connection address
%       .serial: serial number/string
%       .currentlim: diode output current limits
%       .voltagelim: diode compliance voltage limits
%       .description: string with a description of the LDC
%
%   Parameters:
%     ldcID: LDC ID; pass 'list' for a cell array of available IDs,
%               'types' for available types
%
% TODO:
%   - 

function ldcStruct = mapLDC(ldcID)
%% Validate and initialize
if ~ischar(ldcID)
    if isnumeric(ldcID)
        ldcID = num2str(ldcID);
    else
        ldcID = char(ldcID);
    end
end

LDCs = cell(0);


%% List of LDCs
% Older LDC
ldcStruct = struct;
ldcStruct.ID = 'old';
ldcStruct.type = 'ILX LDC-3522';
ldcStruct.interface = @instLDC_Newport3500;
ldcStruct.visaAddr = 'GPIB0::2::INSTR';
ldcStruct.serial = '1009';
ldcStruct.currentlim = [0 500];
ldcStruct.voltagelim = [0 10];
ldcStruct.description = 'Older LDC, in storage';
LDCs{end+1} = ldcStruct;

% LDC
ldcStruct = struct;
ldcStruct.ID = 'Station2';
ldcStruct.type = 'ILX LDC-3724';
ldcStruct.interface = @instLDC_Newport3700;
ldcStruct.visaAddr = 'GPIB0::22::INSTR';
ldcStruct.serial = '1103';
ldcStruct.currentlim = [0 500];
ldcStruct.voltagelim = [0 21];
ldcStruct.description = 'LDC at Station 2';
LDCs{end+1} = ldcStruct;


%% Return desired LDC
if strcmpi(ldcID, 'list')
    ldcStruct = cellfun(@(x) x.ID, LDCs, 'UniformOutput', 0);
elseif strcmpi(ldcID, 'types')
    
else
    ii = find(cellfun(@(x) strcmpi(x.ID, ldcID), LDCs) | cellfun(@(x) strcmpi(x.serial, ldcID), LDCs));

    if ii>0
        ldcStruct = LDCs{ii};
    else
        error('LDC %s not found!', ldcID);
    end
end

end
