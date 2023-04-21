%% Take continuous DSO measurements

% Sequence settings
ch = 4;
dev = '165.1';
lambda = 1030;
measurement = 'thermal_FP';
wg = '2µm_SSC_half';

savPath='~/labshare/measurements/station2';


%% Set up plot
h = figureSize(1, 800, 600); clf(h); hold on;
plH = plot([1 2], [NaN NaN], '-', 'MarkerSize', 10, 'LineWidth', 3);
grid on;
xlabel('Time'); ylabel('PD [V]');
set(gcf, 'CurrentCharacter', '_');

% Title
title('Continuous DSO Trace', 'FontSize', 20, 'FontName', 'Source Sans Pro');


%% Execute
disp('Saving traces continuously: ');

lastKey = get(gcf, 'CurrentCharacter'); i=0; lastOut=0;
while (isempty(lastKey) || (lastKey == '_')) && isvalid(h)
    i = i+1;

    % Get data
    [Y, X] = dev_DSOgetTrace(ch, mapDSO('Station2USB').visaAddr, 1);
    
    % Save data
    dataFile = sprintf('%s-%s-%s-%inm-%s-ch%i-%s.mat', datestr(now, 'yyyymmdd'), ...
        dev, measurement, lambda, wg, ch, datestr(now, 'Thhmmss.FFF'));
    save([savPath dataFile], 'X','Y', 'dev', 'lambda', 'measurement', 'wg', 'ch');
    
    % Update display
    fprintf(repmat('\b', [1 lastOut]));
    lastOut = fprintf('%i', i);
    
    if isvalid(h)
        % Update plot
        plH.XData = X;
        plH.YData = Y;
        drawnow;
    end
    
    if isvalid(h)
        % Check for abort
        lastKey = get(h, 'CurrentCharacter');
    end
end

fprintf("\nMeasurement concluded.\n");
