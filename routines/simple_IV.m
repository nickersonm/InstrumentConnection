%% Simple IV curve using DMM
% Michael Nickerson 2020-08-03
%   Updated 2021-03-25
clear;

%% Setup
% Record Parameters
die = '161D1.2';
dev1 = '16';
dev2 = ''; % Comment out or empty to not measure
measurement = 'IV';

% Measurement Parameters
double = 0;
N = 15; %N2 = NaN;
Vrange = [-15, 1];
% Vrange = [-10, 10];
N2 = 6; Vrange2 = [1, 1.8];
avgT = 0.01;

% Defaults
dmmWires = 2;
Ilim = 50e-3;    % Compliance current
dmmID1 = 'GPIB16';
dmmID2 = 'GPIB26';

% Allocate storage
V1 = linspace(min(Vrange), max(Vrange), N)';
if exist('N2', 'var') && ~isnan(N2)
    V1 = unique([V1; linspace(min(Vrange2), max(Vrange2), N2)']);
end
V1 = unique(V1);
if double > 0
    V1 = [V1; V1(end:-1:1)];
end
N = numel(V1);
V2 = V1;
I1 = NaN(size(V1)); I2 = I1;

% Set up save names
if ~exist('dev2','var') || isempty(dev2) || isnan(dev2)
    dev2 = ''; dev2l = ' ';
    devs = dev1;
else
    devs = [dev1 ',' dev2];
    dev2l = dev2;
end
savName = sprintf('%s_%s-%s_%s_%s', datestr(now, 'yyyymmdd'), ...
    die, devs, measurement, datestr(now, 'Thhmmss'));

savPath='~/labshare/measurements/station2';


%% Set up plot
[figH, axH, plotH] = plotStandard2D([V1, I1], 'style', 'x', 'legend', dev1, ...
                                    [V2, I2], 'style', 'o', 'legend', dev2l, ...
                                    'fig', 1, 'legendloc', 'nw', ...
                                    'xlabel', 'Bias [V]', ...
                                    'ylabel', 'Current [mA]', ...
                                    'title', ['IV: ' [die '-' devs]]);
set(gcf, 'CurrentCharacter', '_');

%% Run
fprintf('Starting voltage sweep of %s.%s\n ', die, dev1);
ifaceDMM(dmmID1, 'reset', 'avg', avgT, 'voltage', -.01, 'on', 'ilimit', Ilim, 'w', dmmWires);
if ~isempty(dev2)
    ifaceDMM(dmmID2, 'reset', 'avg', avgT, 'voltage', -.01, 'on', 'ilimit', Ilim, 'w', dmmWires);
end

lastOutB = 0;
for i=1:N
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('%.0f%%.. ', 100.0*i/N);
    
    % Measure
    IV = ifaceDMM(dmmID1, 'voltage', V1(i));
    I1(i) = IV(1)*1e3; V1(i) = IV(2);
    if ~isempty(dev2)
        IV = ifaceDMM(dmmID2, 'voltage', V2(i));
        I2(i) = IV(1)*1e3; V2(i) = IV(2);
    end
    
    % Update plots
    plotH(1).XData = V1;
    plotH(1).YData = I1;
    if ~isempty(dev2)
        plotH(2).XData = V2;
        plotH(2).YData = I2;
    end
    drawnow; pause(0.01);
    
    % Check for abort
    lastKey = get(figH, 'CurrentCharacter');
    if ~isempty(lastKey) && (lastKey ~= '_')
        disp('Keypress detected: aborting');
        break;
    end
end

% Reset to default
ifaceDMM(dmmID1, 'voltage', -10, 'avg', 0, 'off');
if ~isempty(dev2)
    ifaceDMM(dmmID2, 'voltage', -10, 'avg', 0, 'off');
end

disp('Done measuring');


%% Save results
print([savPath savName '.png'], '-dpng');
save([savPath savName '_IV.mat'],'I1','V1', 'I2', 'V2', 'devs', 'die', 'measurement', 'Ilim', 'dmmWires', 'dmmID1', 'dmmID2');

