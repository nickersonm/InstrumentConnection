%% Use DSO measurements as voltage sampling

% Sequence settings
ch = 4;
dev = '165.4';
lambda = 1030;
measurement = 'thermal_FP';
wg = '1.5um_SSC_pol1';

savPath='C:\Users\Michael Nickerson\LabShare\Measurements\TWP\';


%% Set up plot
h = figureSize(1, 800, 600); clf(h); hold on;
plH = plot([1 2], [NaN NaN], '-', 'MarkerSize', 10, 'LineWidth', 3);
grid on;
xlabel('Time'); ylabel('PD [V]');
set(gcf, 'CurrentCharacter', '_');

% Title
title('Continuous DSO Measurement', 'FontSize', 20, 'FontName', 'Source Sans Pro');


%% Execute
t = []; V = [];
lastKey = get(gcf, 'CurrentCharacter'); i=0; lastOut=0;
while (isempty(lastKey) || (lastKey == '_')) && isvalid(h)
    i = i+1;
    
    % Get data
    V = [V, mean(dev_DSOgetTrace(ch, mapDSO('Station2USB').visaAddr, 1))];
    t = [t, posixtime(datetime('now'))];
    
    if isvalid(h)
        % Update plot
        plH.XData = t-min(t);
        plH.YData = V;
        drawnow;
    end
    
    if isvalid(h)
        % Check for abort
        lastKey = get(h, 'CurrentCharacter');
    end
end

% Save data
dataFile = sprintf('%s-%s-%s-%inm-%s-ch%i-%s.mat', datestr(now, 'yyyymmdd'), ...
    dev, measurement, lambda, wg, ch, datestr(now, 'Thhmmss.FFF'));
save([savPath dataFile], 't','V', 'dev', 'lambda', 'measurement', 'wg', 'ch');

fprintf("\nMeasurement concluded.\n");
