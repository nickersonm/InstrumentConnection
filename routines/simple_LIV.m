%% Simple LVI curve using a LDC, Sourcemeter, and power meter
% Michael Nickerson 2020-07-06

%% Setup
die = '122D3.1';
dev = '6.1z';
lambda = 1030;
pol = 2;    % 1 = high EA, 2 = low EA

measurement = 'LIV';
savName = sprintf('%s_%s-%s_%s_%i-p%i_%s', datestr(now, 'yyyymmdd'), ...
    die, dev, measurement, lambda, pol, datestr(now, 'Thhmmss'));

N = 50;
% Ilaser = 0;   % External source
% Ilaser = 111e-3;    % ~10mW 980nm into lensed fiber in homodyne setup
Ilaser = 105e-3;    % ~3mW 1030nm into lensed fiber in homodyne setup
Vrange = [-4, 0];
avgT = 0.50;

% Defaults
ldcID = 'Station2';
pmID = 'Station2';
dmmID = 'GPIB16';
Ilim = 5e-3;    % Compliance current
measT = 0.10;   % Base measurement rate, random-averaged to longer times

% Allocate storage
V = linspace(min(Vrange), max(Vrange), N)';
% V = V(randperm(N)); % Randomly sample to avoid time-based effects
avgN = round(avgT/measT); N = N*avgN;
V = repmat(V, [avgN 1]);    % Duplicate measurement points for averaging
I = NaN(size(V)); L = I;

% Set up save names
savPath='~/labshare/measurements/station2';
% savFile = [savPath savName '.dat'];


%% Set up plot
[figH, axH, plotH] = plotStandard2D([V, I], 'style', 'x', 'y2', 'legend', 'Current', ...
                                    [V, L], 'style', 'x', 'legend', 'Power', ...
                                    [V, L], 'style', '-', 'legend', 'Smoothed Power', ...
                                    'logy', 'fig', 1, 'legendloc', 'nw', ...
                                    'xlabel', 'Bias [V]', ...
                                    'ylabel', 'Optical Power [mW]', ...
                                    'y2label', 'Current [mA]', ...
                                    'title', ['LVI: ' [die '-' dev]]);


%% Run
set(gcf, 'CurrentCharacter', '_');
fprintf('Starting voltage sweep\n ');
ifaceLDC(ldcID, 'current', Ilaser, 'state', 1);
ifaceDMM(dmmID, 'avg', measT/2, 'voltage', 0, 'on', 'ilimit', Ilim);
ifacePM(pmID, 'wavelength', lambda);

lastOutB = 0;
for i=1:N
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('%.0f%%.. ', 100.0*i/N);
    
    % Measure
    IV = ifaceDMM(dmmID, 'voltage', V(i));
    pause(measT/2);
    L(i) = ifacePM(pmID, 'avg', measT)*1e3;
    I(i) = IV(1)*1e3; V(i) = IV(2);
    
    % Update plots
    set(plotH, 'XData', V);
    plotH(1).YData = I;
    plotH(2).YData = L;
    VL = unique(bindata(V, L), 'rows'); % Sort by rows
    plotH(3).XData = VL(:,1); plotH(3).YData = VL(:,2);
    drawnow; pause(0.01);
    
    % Check for abort
    lastKey = get(figH, 'CurrentCharacter');
    if ~isempty(lastKey) && (lastKey ~= '_')
        disp('Keypress detected: aborting');
        break;
    end
end

% Reset to default
ifaceDMM(dmmID, 'voltage', min(Vrange), 'avg', 0);

disp('Done measuring');


%% Clean up
% ifaceLDC(ldcID, 'state', 0);
ifaceDMM(dmmID, 'voltage', 0, 'avg', 0, 'off');


%% Save results
print([savPath savName '.png'], '-dpng');
save([savPath savName '_IVL.mat'],'L','I','V', 'VL', 'dev', 'die', 'measurement', 'lambda', 'pol');


%% Helper function
% Averages multiple y-values for identical x-values
function xy = bindata(x, y)
    [x, ~, xi] = uniquetol(x, 1e-3);
    y = accumarray(xi, y, [], @nanmean);
    xy = [x(:), y(:)];
end
