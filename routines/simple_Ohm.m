%% Simple resistance using a DMM
% Michael Nickerson 2021-03-25

%% Setup
% Data Parameters
% die = '123.2D1';
% dev = 'MZM1-PP';
% measurement = 'R';

% savName = sprintf('%s_%s-%s_%s_%s', datestr(now, 'yyyymmdd'), ...
%     die, dev, measurement, datestr(now, 'Thhmmss'));

% Defaults
dmmID = 'GPIB16';
avgT = 5.0;
nWire = 4;


%% Initialize
disp('Initializing...');
ifaceDMM(dmmID, 'reset', 't', 0.1, 'w', nWire, 'rmeas');


%% Measure
% dlmwrite([savName '.dat'], ...
%     sprintf('\n\n# R\tRerr\tI\tIerr\tV\tVerr\tPad1\tPad2'), ...
%      'Delimiter', '', '-append');

ifaceDMM(dmmID, 't', 0.05, 'rmeas');
[IV, R, err] = ifaceDMM(dmmID, 't', avgT, 'rmeas');

fprintf('R: %.4g ± %.4g ohms\n', R, err(3));
%     dlmwrite([savName '.dat'], ...
%         [R err(3) IV(1) err(1) IV(2) err(2) pads(i,1), pads(i,2)], ...
%         'Delimiter', '\t', '-append');


%% Clean up
ifaceDMM(dmmID, 'state', 0, 't', 0.1);
