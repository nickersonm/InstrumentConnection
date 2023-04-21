%% [L]IV curve using two DMMs and reverse-biased SOA or PM
% Michael Nickerson 2022-07-19
clear;

%% Setup
% Record Parameters
die = '155D1.3';
dev = '5-soa1';
measurement = 'soaLIV';

savName = sprintf('%s_%s-%s_%s_%s', datestr(now, 'yyyymmdd'), ...
    die, dev, measurement, datestr(now, 'Thhmmss'));

% Measurement Parameters
double = 0;
N = 10; %N2 = NaN;
% Vrange = [-15, 2];
Vrange = [-5, 1];   % Fails open-circuit at 7-8V!
N2 = 10; Vrange2 = [1, 4];
Ilim = 30e-3;    % Compliance current; most fail 50-75 mA
endstate = 'on';

% Defaults
dmmID = 'GPIB16';
dmmIDsoa = 'GPIB26';
dmmWires = 2;
Vsoa = -10;  % SOA measurement bias
avgT = 0.10;
Rls = 5e5; % Initial guess

% Allocate storage
V = linspace(min(Vrange), max(Vrange), N)';
if exist('N2', 'var') && ~isnan(N2)
    V = [V; linspace(min(Vrange2), max(Vrange2), N2)'];
end
V = unique(V);
if double > 0
    V = [V; V(end:-1:1)];
end
N = numel(V);
% Vc = linspace(min(Vc), max(Vc), Nc)';
I = NaN(size(V)); Isoa = I;


% Set up save names
savPath='~/labshare/measurements/station2';


%% Set up plot
[figH, axH, plotH] = plotStandard2D([V, I], 'style', 'x', 'legend', 'Device', ...
                                    [V, Isoa], 'y2', 'style', ':', 'legend', 'SOA Excess', ...
                                    'fig', 1, 'legendloc', 'nw', ...
                                    'xlabel', 'Bias [V]', ...
                                    'ylabel', 'Device Current [mA]', ...
                                    'y2label', 'SOA Excess Current [mA]', ...
                                    'title', ['[L]IV: ' [die '-' dev]]);
set(gcf, 'CurrentCharacter', '_');


%% Run
% Initialize
ifaceDMM(dmmID, 'reset', 'avg', avgT, 'off', 'ilimit', Ilim, 'w', dmmWires);
ifaceDMM(dmmIDsoa, 'reset', 'avg', avgT, 'on', 'voltage', Vsoa, 'ilimit', Ilim, 'w', dmmWires);
Isoa0 = ifaceDMM(dmmIDsoa); Isoa0 = Isoa0(1)*1e3;
ifaceDMM(dmmID, 'voltage', -.01, 'on');

% Take voltage sweep
fprintf('Starting voltage sweep of %s.%s\n ', die, dev);
lastOutB = 0;
for i=1:N
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('%.0f%%.. ', 100.0*i/N);
    
    % Measure
    IV = ifaceDMM(dmmID, 'voltage', V(i));
    I(i) = IV(1)*1e3; V(i) = IV(2);
    IV = ifaceDMM(dmmIDsoa);
    Isoa(i) = IV(1)*1e3;
    
    % Fit R if V≤0
    if V(i) <= 0 && i > 1
        Ils = Isoa0-Isoa;
        Rfit = fit(V(1:i)-Vsoa, Ils(1:i), fittype('1e3*x*Rinv'), ...
            'StartPoint', 1/Rls, 'Lower', 0);
        Rls = 1/Rfit.Rinv;
%         figure(2); plot(V-Vsoa, Ils, V-Vsoa, Rfit(V-Vsoa));
    end
    
    % Update plots
    set(plotH, 'XData', V);
    plotH(1).YData = I;% - 1e3*(V-Vsoa)/Rls;
    plotH(2).YData = Isoa-Isoa0 + 1e3*(V-Vsoa)/Rls;
    drawnow; pause(0.01);
    
    % Check for abort
    lastKey = get(figH, 'CurrentCharacter');
    if ~isempty(lastKey) && (lastKey ~= '_')
        disp('Keypress detected: aborting');
        break;
    end
end

% Reset to default
ifaceDMM(dmmID, 'voltage', -10, 'avg', 0, endstate);
ifaceDMM(dmmIDsoa, 'voltage', -10, 'avg', 0, endstate);

disp('Done measuring');


%% Save results
print([savPath savName '.png'], '-dpng');
save([savPath savName '_IV.mat'],'I','V','Isoa','Isoa0','Vsoa','Rls');

