%% mapDMM.m  MN 2020-03-20
% Maps available DMMs to their VISA resources and other attributes
% 
% Requirements:
%   - None
% 
% Usage: dmmStruct = mapDMM(dmmID)
%   Returns:
%     dmmStruct: DMM information:
%       .ID: string to use as dmmID
%       .type:  string containing the model/manufacturer to select correct SCPI commands
%       .interface: function handle to interface function
%       .visaAddr: string containing the typical VISA connection address
%       .serial: serial number/string
%       .currentlim: 1x2 vector containing the min and max current, in amps
%       .voltagelim: 1x2 vector containing the min and max voltage, in volts
%       .description: string with a description of the DMM
%       .maxtime: reasonable estimate of maximum on-device averaging time
%
%   Parameters:
%     dmmID: DMM ID; pass 'list' for a cell array of available IDs,
%               'types' for available types
%
% TODO:
%   - 

function dmmStruct = mapDMM(dmmID)
%% Validate and initialize
if ~ischar(dmmID)
    if isnumeric(dmmID)
        dmmID = num2str(dmmID);
    else
        dmmID = char(dmmID);
    end
end

DMMs = cell(0);


%% List of DMMs
% Sample DMM
dmmStruct = struct;
dmmStruct.ID = 'GPIB26';
dmmStruct.type = 'Keithley Sourcemeter 2400';
dmmStruct.interface = @instDMM_SM2400;
dmmStruct.visaAddr = 'GPIB0::26::INSTR';
dmmStruct.serial = '1309135';
dmmStruct.currentlim = [-1 1];
dmmStruct.voltagelim = [-40 40];
dmmStruct.maxtime = 10/60;
dmmStruct.description = 'Upper sourcemeter at station 2 labeled "GPIB26"';
DMMs{end+1} = dmmStruct;

dmmStruct = struct;
dmmStruct.ID = 'GPIB16';
dmmStruct.type = 'Keithley Sourcemeter 2400';
dmmStruct.interface = @instDMM_SM2400;
dmmStruct.visaAddr = 'GPIB0::16::INSTR';
dmmStruct.serial = '1083863';
dmmStruct.currentlim = [-1 1];
dmmStruct.voltagelim = [-40 40];
dmmStruct.maxtime = 10/60;
dmmStruct.description = 'Lower sourcemeter at station 2 labeled "GPIB16"';
DMMs{end+1} = dmmStruct;

dmmStruct = struct;
dmmStruct.ID = 'DG1022';
dmmStruct.type = 'Rigol DG1022';
dmmStruct.interface = @instDMM_DG1022;
dmmStruct.visaAddr = 'USB0::0x1AB1::0x0642::DG1ZA221601113::0::INSTR';
dmmStruct.serial = 'DG1ZA221601113';
dmmStruct.currentlim = [-1 1]*0.2;
dmmStruct.voltagelim = [-10 10];
dmmStruct.maxtime = 1/60;
dmmStruct.description = 'Rigol DG1022 at phase measurement station';
DMMs{end+1} = dmmStruct;

dmmStruct = struct;
dmmStruct.ID = 'N9310';
dmmStruct.type = 'Keysight N9310';
dmmStruct.interface = @instDMM_N9310;
dmmStruct.visaAddr = 'USB0::0x0957::0x2018::01152078::0::INSTR';
dmmStruct.serial = '108000218';
dmmStruct.currentlim = [-0.44 0.44];
dmmStruct.voltagelim = [0 2.2];
dmmStruct.maxtime = 1/60;
dmmStruct.description = 'Agilent N9310 on cart';
DMMs{end+1} = dmmStruct;

dmmStruct = struct;
dmmStruct.ID = 'MG3694C';
dmmStruct.type = 'Anritsu MG369X';
dmmStruct.interface = @instDMM_MG3690;
dmmStruct.visaAddr = 'GPIB1::5::INSTR';
dmmStruct.serial = '142308';
dmmStruct.currentlim = [-0.44 0.44];
dmmStruct.voltagelim = [0 2.2];
dmmStruct.maxtime = 1/60;
dmmStruct.description = 'Anritsu MG3694C 40GHz signal generator';
DMMs{end+1} = dmmStruct;


%% Return desired DMM
if strcmpi(dmmID, 'list')
    dmmStruct = cellfun(@(x) x.ID, DMMs, 'UniformOutput', 0);
elseif strcmpi(dmmID, 'types')
    
else
    ii = find(cellfun(@(x) strcmpi(x.ID, dmmID), DMMs) | cellfun(@(x) strcmpi(x.serial, dmmID), DMMs));

    if ii>0
        dmmStruct = DMMs{ii};
    else
        error('DMM %s not found!', dmmID);
    end
end

end
