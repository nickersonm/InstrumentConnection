%% Simple TLM using a DMM
% Michael Nickerson 2020-08-03

%% Setup
% Parameters
savName = '20200803-107D1.1-TLM1';

% Defaults
dmmID = 'GPIB26';
avgT = 5.0;
nWire = 2;
pads = 1:7;


%% Initialize
disp('Initializing...');
ifaceDMM(dmmID, 'reset', 't', 0.1, 'w', nWire, 'rmeas');
pads = combnk(pads,2);


%% Measure pad combinations
dlmwrite([savName '.dat'], ...
    sprintf('\n\n# R\tRerr\tI\tIerr\tV\tVerr\tPad1\tPad2'), ...
    'Delimiter', '', '-append');

for i=1:size(pads,1)
    ifaceDMM(dmmID, 'state', 0, 't', 0);
    if strncmpi(input(...
            sprintf('Measure pads %i to %i [Enter/q]:', pads(i,1), pads(i,2) ), ...
            's'), 'q', 1)
        break;
    end
    ifaceDMM(dmmID, 't', 0.05, 'rmeas');
    [IV, R, err] = ifaceDMM(dmmID, 't', avgT, 'rmeas');
    
    fprintf('R: %.4g\n', R);
    dlmwrite([savName '.dat'], ...
        [R err(3) IV(1) err(1) IV(2) err(2) pads(i,1), pads(i,2)], ...
        'Delimiter', '\t', '-append');
end


%% Clean up
ifaceDMM(dmmID, 'state', 0, 't', 0.1);
