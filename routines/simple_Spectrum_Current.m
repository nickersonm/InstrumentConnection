%% Simple spectrum at multiple drive currents
% Michael Nickerson 2023-09-08
clear;

%% Setup
% Record Parameters
die = "184.08AT";
dev = "1.04-FP-900";
measurement = "SpectrumI";
span = [950 1150];
pol = 0;    % 0 = ASE
            % 1 = high coupling transmission
            % 2 = low coupling transmission

% Measurement Parameters
I = [linspace(50, 400, 11)]*1e-3;
direction = "ascend";
coolTime = 0;  % Time to cool between measurements
coolI = 75e-3;  % Current to start cooling at
specMode = "high2";
specN = 2001;

% Defaults
Vlim = 10;    % Compliance voltage
dmmID = "GPIB16";
dmmWires = 4;
specID = "AQ6370D";
minP = -100;    % Crop power below this
specAvg = 1;
specRes = 0.5;    % nm

% Continuous coupling optimization
pmID = 'ESImeas';
coupleMinPow = 0e-3;   % Run coupling if under this power

% Allocate storage
I = sort(unique(I(:)), direction);
N = numel(I);
L = linspace(min(span), max(span), specN);
P = NaN(N, specN);

% Set up save names
savName = sprintf("%s_%s-%s_%s_pol%i_%s", string(datetime("now", "Format", "yyyyMMdd")), ...
    die, dev, measurement, pol, "T"+string(datetime("now", "Format", "hhmmss")));

savPath="C:\Users\IMPRESS Lab\LabShare\Measurements\ESI1030\";


%% Set up plot
figH = figureSize(2, 800, 600); clf(figH);
[~,axH] = contourf(L, sort(I)*1e3, smoothdata(P, 2, "gaussian", 15), 25);

xlim(sort(span));
ylim([min(I), max(I)]);
ylabel(colorbar, "Power [dB]", 'FontSize', 16, 'FontName', 'Consolas', 'FontWeight', 'Bold');
ylabel("Current [mA]", 'FontSize', 16, 'FontName', 'Consolas', 'FontWeight', 'Bold');
xlabel("Wavelength [nm]", 'FontSize', 16, 'FontName', 'Consolas', 'FontWeight', 'Bold');
title("Spectrum: "+die+"-"+dev, 'FontSize', 20, 'FontName', 'Source Sans Pro', 'FontWeight', 'Bold');

view(2);
axis tight; grid off; shading interp;

set(gcf, 'CurrentCharacter', '_');


%% Initialize and run
fprintf('Starting spectral-current sweep of %s.%s\n ', die, dev);
ifaceDMM(dmmID, 'current', I(1), 'vlimit', Vlim, 'w', dmmWires, 'on');
ifaceSpectrometer(specID, 'reset', 'span', span, 'avg', specAvg, 'points', specN, 'mode', specMode, 'res', specRes, 'nomeas');

lastOutB = 0;
for i=1:N
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('%.0f%%.. ', 100.0*i/N);
    
    % Cooldown
    if coolTime > 0 && i > 1 && I(i-1) > coolI
        ifaceDMM(dmmID, 'current', 0, 'on');
        tic;
        while toc < coolTime
            lastOutB2 = fprintf('; cooling %.0f s', coolTime-toc);
            pause(0.5);
            fprintf(repmat('\b', [1 lastOutB2]));
        end
    end
    
    % Set current
    IV = ifaceDMM(dmmID, 'current', I(i), 'on');
    I(i) = IV(1); pause(0.1);

    % Run coupling if needed
    if coupleMinPow > 0 && I(i) > 0
        if ifacePM(pmID, 'avg', 0.5) < coupleMinPow
            doCouple(pol);
            pause(0.5);
        end
    end
    
    % Check for abort
    lastKey = get(figH, 'CurrentCharacter');
    if ~isempty(lastKey) && (lastKey ~= '_')
        disp('Keypress detected: aborting');
        break;
    end
    
    % Measure spectrum
    LP = ifaceSpectrometer(specID);
    L      = LP(:,1)*1e9;   % nm
    P(i,:) = LP(:,2);       % dB
    P(P<minP) = NaN;    % Crop low powers
    
    % Update plots
    axH.XData = L;
    axH.YData = sort(I)*1e3;
    axH.ZData = smoothdata(P, 2, "gaussian", 15);
    axH.LevelList = linspace(min(P, [], 'all'), max(P, [], 'all'), 25);
    drawnow; pause(0.01);
    
    % Check for abort
    lastKey = get(figH, 'CurrentCharacter');
    if ~isempty(lastKey) && (lastKey ~= '_')
        disp('Keypress detected: aborting');
        break;
    end
end


%% Clean up
disp('Done measuring');
ifaceDMM(dmmID, 'voltage', -2, 'off');


%% Save results
figure(2);
print(savPath+savName+".png", '-dpng');
save(savPath+savName+".mat",'I','L','P', ...
    'dev', 'die', 'measurement', 'pol', ...
    'span', 'coolTime', 'coolI', ...
    'specMode', 'specN', 'specAvg', 'specRes', ...
    'Vlim', 'dmmID', 'dmmWires', 'specID', 'minP');


%% Helper function
function doCouple(pol)
    % Run DMM coupling if in transmission
    if pol == 0
        piezoID = {'ESIleft'};
        chs = {'xz'};    % For output counting, don't change distance
        spanV = [10 5];  % Search ± around center
    else
        piezoID = {'ESIright', 'ESIleft'};
        chs = {'yz', 'xz'};
        spanV = [10 5];  % Search ± around center
    end
    
    % Run coupling
    simple_CouplePM;
end
