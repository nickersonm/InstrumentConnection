%% Simple script to stay aligned overnight
% Michael Nickerson 2022-01-17
clear; close('all');

%% Setup
lambda = 1030;
coupleMinPow = 60e-6;   % Run coupling again if under this power
pauseTime = 5*60;  % Check power every 5m

% Equipment settings
dcDMM = 'GPIB16';
aomDMM = 'GPIB26';
pmID = 'Station2';

% Initialize equipment
ifaceDMM(dcDMM, 'off');
ifaceDMM(aomDMM, 'off');


% Start loop
while true
    fprintf('Checking power\n');
    if ifacePM(pmID, 'softavg', 0.5) < coupleMinPow
        fprintf('Running coupling\n');
        simple_CouplePM; close('all');
    end
    fprintf('Waiting %.4g minutes to check\n', pauseTime/60);
    pause(pauseTime);
end
