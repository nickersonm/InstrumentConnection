%% mapLaser.m  MN 2018-09-24
% Maps available lasers to their VISA resources and other attributes
% 
% Requirements:
%   - None
% 
% Usage: laserStruct = mapLaser(laserID)
%   Returns:
%     laserStruct: Laser information:
%       .ID: string to use as laserID
%       .type:  string containing the model/manufacturer to select correct SCPI commands
%       .interface: function handle to interface function
%       .visaAddr: string containing the typical VISA connection address
%       .serial: serial number/string
%       .powerlim: 1x2 vector containing the min and max power, in watts
%       .wavelim: 1x2 vector containing the min and max wavelength, in nm
%       .description: string with a description of the laser
%
%   Parameters:
%     laserID: Laser ID; pass 'list' for a cell array of available IDs,
%               'types' for available types
%
% TODO:
%   - 

function laserStruct = mapLaser(laserID)
%% Validate and initialize
if ~ischar(laserID)
    if isnumeric(laserID)
        laserID = num2str(laserID);
    else
        laserID = char(laserID);
    end
end

lasers = cell(0);


%% List of lasers
% Sample laser
laserStruct = struct;
laserStruct.ID = 'test';
laserStruct.type = 'T100S';
laserStruct.interface = @instLaser_T100S;
laserStruct.visaAddr = '';
laserStruct.serial = '12345';
laserStruct.powerlim = [1e-12 1e-2];
laserStruct.wavelim = [900 1800];
laserStruct.description = 'Variable wavelength laser';
lasers{end+1} = laserStruct;


%% Return desired meter
if strcmpi(laserID, 'list')
    laserStruct = cellfun(@(x) x.ID, lasers, 'UniformOutput', 0);
elseif strcmpi(laserID, 'types')
    
else
    ii = find(cellfun(@(x) strcmpi(x.ID, laserID), lasers) | cellfun(@(x) strcmpi(x.serial, laserID), lasers));

    if ii>0
        laserStruct = lasers{ii};
    else
        error('Laser %s not found!', laserID);
    end
end

end
