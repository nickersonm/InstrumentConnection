%% Quick and dirty DSO data acquisition
% MN 2020-07-16

%% Parameters
die = "184.11FP";
dev = "90dSDT2";
lambda = 1030;
pol = 2;    % 0 = zero, 1 = high coupling, 2 = low coupling
measurement = 'MZM';
maxPoints = 0;  % Capture maximum number of points?
chs = [4,1,2];

savName = sprintf("%s_%s-%s_%s-%inm_pol%i_%s", string(datetime("now", "Format", "yyyyMMdd")), ...
    die, dev, measurement, lambda, pol, "T"+string(datetime("now", "Format", "hhmmss.SSS")));
savPath="C:\Users\IMPRESS Lab\LabShare\Measurements\ESI1030\";

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

save(savPath+savName+".mat", 'X', 'Y123', 'dev', 'die', 'lambda', 'measurement', 'pol', 'dsoAddr', 'chs');

