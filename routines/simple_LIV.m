%% Simple LVI curve using a sourcemeter and power meter, external input
% Michael Nickerson 2020-07-06
%   Updated 2023-09-05
clear;

%% Setup
% Record Parameters
die = "185.08";
dev = "1.06";
pol = 0;    % 0 = ASE/laser, 1 = high coupling, 2 = low coupling
measurement = "LIV";
lambda = 1030;
Pin = 0;  % Input power, W, for records only

% Measurement Parameters
I = [linspace(0,30,10) linspace(30, 500, 20)]*1e-3;
Vlim = 10;    % Compliance voltage
direction = "ascend";
double = 1;
zero = 1;

% Defaults
dmmID = "GPIB16";
dmmWires = 4;
pmID = "Station2";
avgT = 0.2;

% Allocate storage
I = sort(unique(I(:)), direction);
if double > 0
    I = [I; I(end:-1:1)];
end
N = numel(I);
V = NaN(size(I)); L = V;

% Set up save names
savName = sprintf("%s_%s-%s_%s-%inm_pol%i_%s", string(datetime("now", "Format", "yyyyMMdd")), ...
    die, dev, measurement, lambda, pol, "T"+string(datetime("now", "Format", "hhmmss")));

savPath="~/labshare/measurements/station2";


%% Set up plot
[figH, axH, plotH] = plotStandard2D([I*1e3, V], 'style', 'x', 'y2', 'legend', 'Current', ...
                                    [I*1e3, L*1e3], 'style', 'x', 'legend', 'Power', ...
                                    'logy', 'fig', 2, 'legendloc', 'nw', ...
                                    'y2label', 'Bias [V]', ...
                                    'ylabel', 'Optical Power [mW]', ...
                                    'xlabel', 'Current [mA]', ...
                                    'title', "LIV: "+die+"-"+dev+sprintf(", pol%i", pol));
set(gcf, 'CurrentCharacter', '_');


%% Run
fprintf('Starting current sweep of %s.%s\n ', die, dev);
ifaceDMM(dmmID, 'avg', avgT/2, 'current', 0, 'vlimit', Vlim, 'w', dmmWires, 'on');
ifacePM(pmID, 'wavelength', lambda, 'avg', avgT);

L0 = 0;
if exist('zero', 'var') && zero == 1
    ifaceDMM(dmmID, 'current', -1e-3);
    L0 = ifacePM(pmID, 'avg', 1);
end

lastOutB = 0;
for i=1:N
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('%.0f%%.. ', 100.0*i/N);
    
    % Measure
    IV = ifaceDMM(dmmID, 'current', I(i)); pause(avgT);
    I(i) = IV(1); V(i) = IV(2);
    L(i) = max( [ifacePM(pmID, 'avg', avgT)-L0, 1e-13]);
    
    % Update plots
    set(plotH, 'XData', I*1e3);
    plotH(1).YData = V;
    plotH(2).YData = L*1e3;
    drawnow; pause(0.01);
    
    % Check for abort
    lastKey = get(figH, 'CurrentCharacter');
    if ~isempty(lastKey) && (lastKey ~= '_')
        disp('Keypress detected: aborting');
        break;
    end
end


%% Clean up
disp('Done measuring');
ifaceDMM(dmmID, 'voltage', -2, 'avg', 0, 'off');


%% Save results
figure(2);
print(savPath+savName+".png", '-dpng');
save(savPath+savName+".mat",'L','I','V', 'dev', 'die', 'measurement', 'lambda', 'pol', 'Pin', 'L0', 'zero');

