%% Continuous DMM current readout
% Michael Nickerson 2022-02-24

%% Setup
% Definitions
N = 200;
dmmID = 'GPIB16';
dmmWires = 2;
Ilim = 5e-3;    % DMM compliance current
dmmV = -15;
movN = 10;

% Allocate storage
I = NaN(N,1);


%% Set up plot
h = figureSize(1, 800, 600); clf(h); hold on;
plH = plot(1:N, I, 'x', 'MarkerSize', 10, 'LineWidth', 3);
plH2 = plot(1:N, smooth(I, movN), '-', 'LineWidth', 2);
grid on;
xlabel('Sample'); ylabel('DMM Current [mA]');

% Title
title('Continuous DMM Current Measurement', 'FontSize', 20, 'FontName', 'Source Sans Pro');


%% Run
set(gcf, 'CurrentCharacter', '_');
disp('Starting read');
ifaceDMM(dmmID, 'w', dmmWires, 'ilimit', Ilim, 'voltage', dmmV, 'avg', 0, 'on');

lastKey = get(gcf, 'CurrentCharacter'); i=0;
while (isempty(lastKey) || (lastKey == '_')) && isvalid(h)
    if i==N
        L = circshift(L, -1);
    else
        i = i+1;
    end
    
    % Measure
    IV = ifaceDMM(dmmID);
    I(i) = IV(1)*1e3;
    
    if isvalid(h)
        % Update plot
        plH.YData = I;
        plH2.YData = smooth(I, movN);
        plH2.YData(isnan(I)) = NaN;
        drawnow;
    end
    
    if isvalid(h)
        % Check for abort
        lastKey = get(h, 'CurrentCharacter');
    end
end

% Clean up
ifaceDMM(dmmID, 'voltage', dmmV, 'avg', 0, 'off');
