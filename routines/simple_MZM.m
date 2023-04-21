%% Measure MZM, modulating one arm and sweeping DC offset of other arm
% Michael Nickerson 2021-11-29

%% Setup
% Record Parameters
die = '122D3.1';
dev = '3.1';

% Measurement Parameters
Ndc = 15;
Vdcrange = [-5, 0];
lambda = 980;
pol = 1;    % 0 = zero, 1 = high mod, 2 = low mod

% Defaults
measurement = 'MZM-dc';
dmmID = 'GPIB16';
dmmWires = 2;
Ilim = 100e-3;    % Compliance current
dsoAddr = mapDSO('Station2USB').visaAddr;
dsoChV = 2;
dsoChPD = 1;  % 1 = high speed DET10C, 4 = amplified PDA05CF2
dsoTime = 200e-6;   % 200µs is longest span for max resolution

% Set up save names
savPath='~/labshare/measurements/station2';


%% Run
fprintf('Starting MZM sweep of %s.%s\n ', die, dev);
ifaceDMM(dmmID, 'avg', 0, 'voltage', -.01, 'on', 'ilimit', Ilim, 'w', dmmWires);

lastOutB = 0;
for Vdc = linspace(max(Vdcrange), min(Vdcrange), Ndc)
    % Set DC arm
    ifaceDMM(dmmID, 'voltage', Vdc);
    pause(0.05); % Wait for it to settle
    
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('DC arm: %.2f%V.. ', Vdc);
    
    % Capture traces and save
    [Y1, X1] = dev_DSOgetTrace(dsoChPD, dsoAddr);
    [Y2, X2] = dev_DSOgetTrace(dsoChV, dsoAddr);
    savName = sprintf('%s_%s-%s_%s_%i-p%i_Vdc%.2f_%s', datestr(now, 'yyyymmdd'), ...
        die, dev, measurement, lambda, pol, Vdc, datestr(now, 'Thhmmss.fff'));
    save([savPath savName '.mat'], 'X1','Y1','X2','Y2', ...
        'dev', 'die', 'lambda', 'measurement', 'pol', 'Vdc');
end

fprintf('\nDone measuring\n');


%% Clean up
ifaceDMM(dmmID, 'voltage', 0, 'avg', 0);
