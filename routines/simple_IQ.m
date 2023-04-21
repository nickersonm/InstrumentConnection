%% IQ heterodyne measurement, AOM + PIC PM
% Michael Nickerson 2022-01-07
clear; close('all');

%% Setup
% Device parameters
die = '121.1D1.5';
dev = '12';
lambda = 1030;
pol = 1;    % 0 = zero, 1 = high EA, 2 = low EA

% Measurement Parameters
waitPol = 1;    % Wait for human to adjust polarization?
coupleMinPow = 65e-6;   % Run coupling if under this power; 0 to disable
measurement = 'IQgsg';
rfFreq = round(10.^linspace(log10(10e6), log10(2.9e8), 20), 4, 'significant')'; % PD doesn't work past ~200MHz
% rfFreq = round(10.^linspace(log10(5e5), log10(25e6), 15), 4, 'significant')';
rfAmp = 1;
dcMax = -2;     % Maximum bias to apply
dcMin = -20;    % Minimum bias to apply
dcStep = -rfAmp*2;
% Optionally override standard bias calculations
dcVals = (dcMax-rfAmp/2):-abs(dcStep):(-abs(dcMin)+rfAmp/2);

% Remove rfFreq too close to AOM frequency
rfFreq = rfFreq(mod(rfFreq, 150e6) >= 4e5);

% Equipment settings
dcDMM = 'GPIB16';
aomDMM = 'GPIB26';
setDG = @setMG3690;  % DG function, defined at end
% setDG = @setDG1022;
dsoAddr = mapDSO('Station2USB').visaAddr;
pmID = 'Station2';

dsoChPD = 4;    % 1 = high speed DET10C, 4 = amplified PDA05CF2
dsoChV = 2;     % Applied voltage
dsoChAOM = 3;   % AOM RF
dmmWires = 2;
Ilim = 5e-3;    % Compliance current
dcPol = -15;    % Bias for polarization setting
dsoMinF = min(mod(rfFreq, 150e6))/10;% Minimum acquired Nyquist frequency; /10 for minimum 10 periods
dsoTime = min(1/dsoMinF, 1e-4);% DSO timescale, max 1e-3 ~= 32MB traces (for highest resolution acquisition)
dsoVDC = 0;     % DSO ChV measuring DC?
dsoVZ = 'low';  % DSO ChV impedance

% Set up save names
savName = @(freq) sprintf('%s_%s-%s_%s-PD%i-%.5gV@%.5gHz-p%i_%s', datestr(now, 'yyyymmdd'), ...
    die, dev, measurement, dsoChPD, rfAmp, freq, pol, datestr(now, 'Thhmmss.FFF'));
savPath='~/labshare/measurements/station2';


%% Run
% Process variables
rfAmp = abs(rfAmp); % Used in various calculations assuming positivity
rfFreq = rfFreq(randperm(length(rfFreq)));  % Randomly permute to avoid conflating time and frequency

% Initialize equipment
ifaceDMM(dcDMM, 'avg', 0, 'off', 'ilimit', Ilim, 'w', dmmWires);
setDSOImpedance(dsoAddr, dsoChV, dsoVZ);
visaWrite(dsoAddr, ':RUN');

% Set polarization
if waitPol == 1
    setDG('off');
    ifaceDMM(dcDMM, 'voltage', dcPol, 'on');
    visaWrite(dsoAddr, sprintf(':TIM:RANG %g', 10/150e6));    % Set DSO timescale to capture maximum points
    input(sprintf('Adjust PIC polarization to %i\n  via DMM current then press return...', pol));
    ifaceDMM(dcDMM, 'off');
    ifaceDMM(aomDMM, 'on');
    input('Adjust AOM polarization\n  then press return...');
end

% Set equipment state
ifaceDMM(dcDMM, 'voltage', dcVals(1), 'off');
visaWrite(dsoAddr, sprintf(':TIM:RANG %g', dsoTime));
setDG('offset', 0, 'amp', rfAmp, 'off', 'sine');

% Start measurement loop
fprintf('Running %s sweep of %s-%s p%i\n', measurement, die, dev, pol);
for i = 1:numel(rfFreq)
    % Run coupling if needed
    if coupleMinPow > 0
        ifaceDMM(aomDMM, 'off');
        setDG('off');
        ifaceDMM(dcDMM, 'off');
        % Run coupling if needed
        if ifacePM(pmID, 'softavg', 0.5) < coupleMinPow
            doCouple(aomDMM, dcDMM, setDG);
        end
    end
    
    % Next frequency
    freq = rfFreq(i);
    fprintf('(%i/%i) Freq: %.4gHz\n ', i, numel(rfFreq), freq);
    
    % Set equipment state
    setDG('freq', freq, 'on');
    ifaceDMM(aomDMM, 'on');
    ifaceDMM(dcDMM, 'voltage', dcVals(1), 'on');
    visaWrite(dsoAddr, sprintf(':CHAN%i:RANG %g;:CHAN%i:OFFS %g', dsoChV, rfAmp*2, dsoChV, dcVals(1)*dsoVDC));
    
    lastOutB = 0;
    for j = 1:numel(dcVals)
        dcOff = dcVals(j);
        % Update progress
        fprintf(repmat('\b', [1 lastOutB]));
        lastOutB = fprintf('(%i/%i) Bias: %.2f%V.. ', j, numel(dcVals), dcOff);
        
        % Set equipment state
        ifaceDMM(dcDMM, 'voltage', dcOff);
        visaWrite(dsoAddr, sprintf(':CHAN%i:OFFS %g', dsoChV, dcOff*dsoVDC));
        pause(0.05); % Wait for it to settle
        
        % Capture traces and save
        [Y123, X] = dev_DSOgetTrace([dsoChPD, dsoChV, dsoChAOM], dsoAddr, 0, round(dsoTime*4e9));
        
        save([savPath savName(freq) '.mat']);
    end
    fprintf(repmat('\b', [1 lastOutB+2]));lastOutB = 0;
    fprintf('; done.\n');
end

fprintf('\nDone measuring\n');


%% Clean up
setDG('off');
ifaceDMM(dcDMM, 'off', 'avg', 0, 'voltage', dcPol);
ifaceDMM(aomDMM, 'off');
visaWrite(dsoAddr, sprintf(':TIM:RANG %g;:CHAN%i:OFFS %g', 10/150e6, dsoChV, dcPol));


%% Helper functions
function doCouple(aomDMM, dcDMM, setDG)
    % Turn off AOM and applied voltage first
    ifaceDMM(aomDMM, 'off');
    ifaceDMM(dcDMM, 'off');
    setDG('off');
    % Run coupling
    simple_CouplePM;
    clear; close('all');
end

function r = setDG1022(varargin)
    r = dev_DG1022setWave(mapDMM('DG1022').visaAddr, 1, varargin{:});
end

function r = setMG3690(varargin)
    r = dev_MG3690setWave(mapDMM('MG3694C').visaAddr, varargin{:});
end

function setDSOImpedance(dsoAddr, ch, Z)
    if strcmpi(Z, 'low')
        visaWrite(dsoAddr, sprintf(':CHAN%i:IMP FIFT', ch));
    else
        visaWrite(dsoAddr, sprintf(':CHAN%i:IMP ONEM', ch));
    end
end
