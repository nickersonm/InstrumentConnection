%% Simple LIV curve using an LDC and power meter
% Michael Nickerson 2020-06-26
%   Updated 2021-04-01

%% Setup
% Record Parameters
die = '123.1.2';
dev = 'MZM4.1';
measurement = 'IV';

savName = sprintf('%s_%s-%s_%s_%s', datestr(now, 'yyyymmdd'), ...
    die, dev, measurement, datestr(now, 'Thhmmss'));

% Measurement Parameters
N = 100;
Irange = [40, 120];  % mA
ldcID = 'Station2';
pmID = 'Station2';
avgT = 2.0;
lambda = 1030;

% Allocate storage
I = linspace(min(Irange), max(Irange), N)';
V = NaN(size(I)); L = V;


%% Set up plot
[figH, axH, plotH] = plotStandard2D([I, V], 'style', 'x', 'y2', 'legend', 'Voltage', ...
                                    [I, L], 'style', 'x', 'legend', 'Power', ...
                                    'fig', 1, 'legendloc', 'nw', ...
                                    'xlabel', 'Current [mA]', ...
                                    'ylabel', 'Optical Power [mW]', ...
                                    'y2label', 'Compliance [V]', ...
                                    'title', ['LIV: ' savName]);


%% Run
set(figH, 'CurrentCharacter', '_');
disp('Starting LIV sweep');
ifaceLDC(ldcID, 'current', I(1)*1e-3, 'avg', avgT, 'state', 1);
ifacePM(pmID, 'wavelength', lambda);

for i=1:N
    % Measure
    IVT = ifaceLDC(ldcID, 'current', I(i) * 1e-3, 'avg', avgT); % Setpoint in A
    L(i) = ifacePM(pmID, 'avg', avgT)*1e3;
    I(i) = IVT(1)*1e3; V(i) = IVT(2);
    
    % Update plot
    plotH(1).XData = I;
    plotH(1).YData = V;
    plotH(2).XData = I;
    plotH(2).YData = L;
    drawnow;
    
    % Check for abort
    lastKey = get(figH, 'CurrentCharacter');
    if ~isempty(lastKey) && (lastKey ~= '_')
        disp('Keypress detected: aborting');
        break;
    end
end

ifaceLDC(ldcID, 'current', 0, 'state', 0);

disp('Done measuring');


%% Fit and plot simple line
LIfit = polyfit(I(L>0.05*max(L)), L(L>0.05*max(L)), 2);
plotStandard2D([I, V], 'style', 'x', 'y2', 'legend', 'Voltage', ...
    [I, L], 'style', 'x', 'legend', 'Power', ...
    [I(L>0.05*max(L)), polyval(LIfit, I(L>0.05*max(L)))], ...
    'style', ':', 'legend', sprintf('%.4g * I + %.4g * I^2', LIfit(2), LIfit(1)), ...
    'fig', 1, 'legendloc', 'nw', ...
    'xlabel', 'Current [mA]', ...
    'ylabel', 'Optical Power [mW]', ...
    'y2label', 'Compliance [V]', ...
    'title', ['LIV: ' savName]);


%% Save results
savPath='~/labshare/measurements/station2';
print([savPath savName '.png'], '-dpng');
save([savPath savName '_LI.mat'],'L','I','V', 'LIfit');
