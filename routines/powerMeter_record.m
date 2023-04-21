%% Record continuous power meter readout
% Michael Nickerson 2020-06-30, modified for saving 2023-03-29

%% Setup
% Record settings
die = '165.4';
dev = '2um_SSC_pol1';
measurement = 'laserthermal_FP';
lambda = 1030;

savPath='C:\Users\Michael Nickerson\LabShare\Measurements\TWP\';

% Instrument settings
pmID = 'Station2';
plotScale = 'log';

% Allocate storage
t = []; L = [];


%% Set up plot
h = figureSize(1, 800, 600); clf(h); hold on;
plH = plot([0 1], [NaN NaN], '-', 'MarkerSize', 10, 'LineWidth', 3);
plH.Parent.YScale = plotScale;
grid on;
xlabel('Sample'); ylabel('Power [W]');

% Title
title('Recorded Power Measurement', 'FontSize', 20, 'FontName', 'Source Sans Pro');


%% Run
set(gcf, 'CurrentCharacter', '_');
disp('Starting read');
ifacePM(pmID, 'wavelength', lambda, 'avg', 0);

lastKey = get(gcf, 'CurrentCharacter');
while (isempty(lastKey) || (lastKey == '_')) && isvalid(h)
    % Measure
    L(end+1) = max( [ifacePM(pmID), 1e-10]);
    t(end+1) = posixtime(datetime('now'));
    
    if isvalid(h)
        % Update plot
        plH.XData = t-min(t);
        plH.YData = L;
        drawnow;
    end
    
    if isvalid(h)
        % Check for abort
        lastKey = get(h, 'CurrentCharacter');
    end
end

% Save data
dataFile = sprintf('%s%s-PM-%s-%s-%inm-%s.mat', datestr(now, 'yyyymmdd'), datestr(now, 'Thhmmss'), ...
    die, measurement, lambda, dev);
save([savPath dataFile], 't','L', 'die', 'lambda', 'measurement', 'dev');

fprintf("\nMeasurement concluded.\n");
