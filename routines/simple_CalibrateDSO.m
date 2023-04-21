%% DSO calibration sweep, using SM2400
% Michael Nickerson 2022-01-10
clear;

%% Setup
% Device parameters
dev = mapDSO('Station2USB').type;

% Measurement Parameters
dcMin = -25;
dcStep = -0.5;
measurement = 'calibration';

% Equipment settings
dcDMM = 'GPIB16';
dsoAddr = mapDSO('Station2USB').visaAddr;

maxPoints = 0;  % Capture maximum number of points?
dsoChV = 2;     % DSO channel number
dmmWires = 4;
Ilim = 5e-3;    % Compliance current

V = 0:-abs(dcStep):-abs(dcMin);
Vi = NaN(size(V));
I = NaN(size(V));
D = NaN(size(V));

% Set up save names
savName = @() sprintf('%s_%s_%s_%s', datestr(now, 'yyyymmdd'), ...
    dev, measurement, datestr(now, 'Thhmmss.FFF'));
savPath='~/labshare/measurements/station2';


%% Run
% Get 'old' timescale if need to change during measurements
if maxPoints == 1
    % Set DSO timescale to capture maximum points
    oldTime = str2double(visaRead(dsoAddr, ':TIM:RANG?'));
    visaWrite(dsoAddr, sprintf(':TIM:RANG %g', 50e-9));
end

% Initialize equipment
ifaceDMM(dcDMM, 'avg', 0.25, 'voltage', 0, 'on', 'ilimit', Ilim, 'w', dmmWires);
if maxPoints == 1
    % Set DSO timescale to capture maximum points
    visaWrite(dsoAddr, sprintf(':TIM:RANG %g', 2e-3));
end
visaWrite(dsoAddr, sprintf(':CHAN%i:RANG %g', dsoChV, 4));

% Start measurement loop
fprintf('Starting calibration sweep of DSO ch %i\n ', dsoChV);
lastOutB = 0;
for i = 1:numel(V)
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('Bias: %.2f%V.. ', V(i));
    
    % Set DC and scope offset
    ifaceDMM(dcDMM, 'voltage', V(i), 'avg', 0);
    visaWrite(dsoAddr, sprintf(':CHAN%i:OFFS %g', dsoChV, V(i)));
    
    % Capture values
    IV = ifaceDMM(dcDMM, 'avg', 0.25);
    I(i) = IV(1);
    Vi(i) = IV(2);
    D(i) = mean(dev_DSOgetTrace(dsoChV, dsoAddr, 1));
end

save([savPath savName() '.mat']);

fprintf('\nDone measuring\n');


%% Clean up
if maxPoints == 1
    visaWrite(dsoAddr, sprintf(':TIM:RANG %g', oldTime));
end
ifaceDMM(dcDMM, 'voltage', 0, 'off', 'avg', 0);
