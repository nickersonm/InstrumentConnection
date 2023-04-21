%% Continuous power meter readout
% Michael Nickerson 2020-06-30

%% Setup
% Definitions
N = 200;
pmID = 'Station2';
plotScale = 'log';
avgT = NaN;
movN = 10; % Moving average
lambda = 1030;

% Allocate storage
L = NaN(N,1);


%% Set up plot
h = figureSize(1, 800, 600); clf(h); hold on;
plH = plot(1:N, L, 'x', 'MarkerSize', 10, 'LineWidth', 3);
plH2 = plot(1:N, smooth(L, movN), '-', 'LineWidth', 2);
plH.Parent.YScale = plotScale;
grid on;
xlabel('Sample'); ylabel('Power [mW]');

% Title
title('Continuous Power Measurement', 'FontSize', 20, 'FontName', 'Source Sans Pro');


%% Run
set(gcf, 'CurrentCharacter', '_');
disp('Starting read');
ifacePM(pmID, 'wavelength', lambda, 'avg', 0);

lastKey = get(gcf, 'CurrentCharacter'); i=0;
while (isempty(lastKey) || (lastKey == '_')) && isvalid(h)
    if i==N
        L = circshift(L, -1);
    else
        i = i+1;
    end
    
    % Measure
    L(i) = max( [ifacePM(pmID, 'avg', avgT)*1e3, 1e-10]);
    
    if isvalid(h)
        % Update plot
        plH.YData = L;
        plH2.YData = smooth(L, movN);
        plH2.YData(isnan(L)) = NaN;
        drawnow;
    end
    
    if isvalid(h)
        % Check for abort
        lastKey = get(h, 'CurrentCharacter');
    end
end
