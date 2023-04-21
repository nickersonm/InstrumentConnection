%% Optimize coupling and take measurement
% Single measurement settings
Ntrace = 15;
doOpt = 0;

% Sequence settings
% Ilaser = 48.0e-3;   % 8.24mW into lensed fiber in homodyne setup
% Ilaser = 80.0e-3;   % ~8.2mW 980nm into lensed fiber in homodyne setup
Ilaser = 0; % Using external source

dev = '107D1.1';
lambda = 1360;
measurement = 'FP';
wg = '4µm2';
pol = 2;    % 1 = high EA, 2 = low EA

savPath='~/labshare/measurements/station2';

dataFile = @(measurement) sprintf('%s-%s-%s-%inm-%s-pol%i-%s.mat', datestr(now, 'yyyymmdd'), ...
    dev, measurement, lambda, wg, pol, datestr(now, 'Thhmmss'));


%% Execute
if doOpt == 1
    simple_CoupleDSO;
end

fprintf('Saving traces: ');

lastOutB = 0;
for i=1:Ntrace
    pause(2);
    
    fprintf(repmat('\b',1,lastOutB));
    lastOutB = fprintf('%i/%i', i, Ntrace);
    
    [Y1, X1] = dev_DSOgetTrace(1, mapDSO('Station2USB').visaAddr);
    [Y2, X2] = dev_DSOgetTrace(2, mapDSO('Station2USB').visaAddr);

    save([savPath dataFile(measurement)], 'X1','Y1','X2','Y2', 'dev', 'lambda', 'measurement', 'wg', 'pol');
end
fprintf('\n');

disp('Measurement concluded.');

return;
%% Take offset if useful
[Y1, X1] = dev_DSOgetTrace(1, mapDSO('Station2USB').visaAddr);
[Y2, X2] = dev_DSOgetTrace(2, mapDSO('Station2USB').visaAddr);
save([savPath dataFile('zero')], 'X1','Y1','X2','Y2', 'dev', 'lambda', 'measurement', 'wg', 'pol');
