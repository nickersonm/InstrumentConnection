%% Quick and dirty DSO data acquisition
% MN 2020-07-16

%% Parameters
die = '121.1D1.5';
dev = '11-fullsweep';
lambda = 1030;
pol = 2;    % 0 = zero, 1 = high EA, 2 = low EA
measurement = 'IQ4';
maxPoints = 1;  % Capture maximum number of points?
chs = [4,2,3];

savName = sprintf('%s_%s-%s_%s_%i-p%i_%s', datestr(now, 'yyyymmdd'), ...
    die, dev, measurement, lambda, pol, datestr(now, 'Thhmmss'));
savPath='~/labshare/measurements/station2';

dsoAddr = mapDSO('Station2USB').visaAddr;


%% Execute
if maxPoints == 1
    % Set DSO timescale to capture maximum points
    oldTime = str2double(visaRead(dsoAddr, ':TIM:RANG?'));
    visaWrite(dsoAddr, sprintf(':TIM:RANG %g', 2e-3));
end

% % Set realtime capture mode
% visaWrite(dsoAddr, ':ACQuire:MODE RTIM');

% Capture and save traces
[Y123, X] = dev_DSOgetTrace(chs, dsoAddr);

if maxPoints == 1
    visaWrite(dsoAddr, sprintf(':TIM:RANG %g', oldTime));
end

save([savPath savName '.mat'], 'X', 'Y123', 'dev', 'die', 'lambda', 'measurement', 'pol', 'dsoAddr', 'chs');

