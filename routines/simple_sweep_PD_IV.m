%% Simple PD IV measurement with swept wavelength source
% Michael Nickerson 2020-12-16

%% Setup
% Naming: what to call the datafile and where to save it.
% Only 'savPath' and 'savName' are needed, but for consistency I assemble those out of other
% variables.  Check line 92 if you remove these.
dev = 'PD#1';
measurement = 'ISweep';

savPath='.\';
savName = sprintf('%s-%s-%s-%s', datestr(now, 'yyyymmdd'), ...
    dev, measurement, datestr(now, 'Thhmmss'));

% Data sweep parameters: wavelength, power, voltage
%   laserP and lambda correspond, e.g. below will measure 1280nm at 1mW and 5mW, then 1300nm at 5mW
laserP = [1e-3, 5e-3, 5e-3];
lambda = [1280, 1280, 1300];
testV  = linspace(0, 10, 0.5);  % Record current at all these voltages

% Instrument settings
laserID = 'test'; % Should match 'ID' in mapLaser.m
dmmID = 'GPIB26';   % Should match 'ID' in mapDMM.m
Ilim = 2e-2;    % DMM compliance current limit
avgT = 0.05;    % Measurement averaging time

% Allocate storage
I = NaN(numel(laserP), numel(testV)); V = I;
Imax = NaN(numel(testV));


%% Set up plot
[figH, axH, plotH] = plotStandard2D([lambda, Imax], 'style', 'x', ...
                                    'logy', 'fig', 1, 'legendloc', 'sw', ...
                                    'xlabel', 'Wavelength [nm]', ...
                                    'ylabel', 'Max Current [A]', ...
                                    'title', ['PD Test: ' savName]);


%% Run
% Check inputs
if size(laserP) ~= size(lambda)
    error('"laserP" and "lambda" need to be the same length!');
end

% Initialize instruments
set(gcf, 'CurrentCharacter', '_');
fprintf('Starting wavelength-voltage sweep\n ');
ifaceLaser(laserID, 'wavelength', lambda(1), 'power', laserP(1), 'state', 1);
ifaceDMM(dmmID, 'avg', avgT, 'voltage', 0, 'on', 'ilimit', Ilim);

% Start sweep
for i=1:numel(laserP)
    % Update progress
    fprintf('  lambda = %.0f, P = %.0f', lambda(i), laserP(i));
    
    % Set laser
    ifaceLaser(laserID, 'wavelength', lambda(i), 'power', laserP(i), 'state', 1);
    pause(0.5); % To let the laser equilibriate
    
    % Run voltage sweep
    for j=1:numel(testV)
        fprintf('.');
        IV = ifaceDMM(dmmID, 'voltage', testV(j));
        I(i,j) = IV(1); V(i,j) = IV(2);
    end
    Imax(i) = max(I(i,:));
    
    % Update plot
    plotH.YData = Imax;
    drawnow; pause(0.01);
    
    % Check for abort - press any key to end loop
    lastKey = get(figH, 'CurrentCharacter');
    if ~isempty(lastKey) && (lastKey ~= '_')
        disp('Keypress detected: aborting');
        break;
    end
end

disp('Done measuring');


%% Clean up
ifaceLaser(laserID, 'state', 0);
ifaceDMM(dmmID, 'voltage', 0, 'avg', 0, 'off');
% ifaceDMM(dmmID, 'voltage', 0, 'avg', 0);  % Use this one if you don't want the DMM to turn off


%% Save results
print([savPath savName '.png'], '-dpng');
save([savPath savName '_lambda-IV.mat'],'lambda','laserP','I', 'V', 'dev', 'measurement');

