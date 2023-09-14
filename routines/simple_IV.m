%% Simple IV curve using DMM
% Michael Nickerson 2020-08-03
%   Updated 2021-03-25
%   Changed to strings 2023-07-27
clear;

%% Setup
% Record Parameters
die = "185.01D2";
dev1 = "A02";
dev2 = "A04"; % Comment out or empty to not measure
measurement = "IV";

% Measurement Parameters
N = 14; Vrange = [-10, 0];
% N2 = 25; Vrange2 = [0, 4.5];
N2 = 11; Vrange2 = [-0.5, 2];
double = 0;
logscale = 1;
direction = "descend";

% Defaults
Ilim = 50e-3;    % Compliance current
avgT = 0.01;
dmmWires = 2;
dmmID1 = 'GPIB16';
dmmID2 = 'GPIB26';

% Allocate storage
V1 = linspace(min(Vrange), max(Vrange), N)';
if exist('N2', 'var') && ~isnan(N2)
    V1 = unique([V1; linspace(min(Vrange2), max(Vrange2), N2)']);
end
V1 = sort(unique(V1), direction);
if double > 0
    V1 = [V1; V1(end:-1:1)];
end
N = numel(V1);
V2 = V1;
I1 = NaN(size(V1)); I2 = I1;

% Set up save names
if ~isstring(dev1); dev1=string(dev1); end
if ~isstring(dev2); dev2=string(dev2); end
if ~exist('dev2','var') || strlength(dev2)==0
    dev2 = ""; dev2l = " ";
    devs = dev1;
else
    devs = dev1+","+dev2;
    dev2l = dev2;
end

savName = sprintf("%s_%s-%s_%s_%s", string(datetime("now", "Format", "yyyyMMdd")), ...
    die, devs, measurement, "T"+string(datetime("now", "Format", "hhmmss")));

savPath="C:\Users\IMPRESS Lab\LabShare\Measurements\ESI1030\";


%% Set up plot
if logscale > 0; yscale = 'logy'; else; yscale = ''; end
[figH, axH, plotH] = plotStandard2D([V1, abs(I1)], 'style', 'x', 'legend', dev1, ...
                                    [V2, abs(I2)], 'style', 'o', 'legend', dev2l, ...
                                    'fig', 1, 'legendloc', 'nw', ...
                                    'xlabel', 'Bias [V]', 'xrange', [min(V1)-0.05, max(V1)+0.06], ...
                                    'ylabel', 'Current [mA]', yscale, ...
                                    'title', "IV: "+die+"-"+devs);
set(gcf, 'CurrentCharacter', '_');

%% Run
fprintf('Starting voltage sweep of %s.%s\n ', die, dev1);
ifaceDMM(dmmID1, 'avg', avgT, 'voltage', -.01, 'on', 'ilimit', Ilim, 'w', dmmWires);
if strlength(dev2)>0
    ifaceDMM(dmmID2, 'avg', avgT, 'voltage', -.01, 'on', 'ilimit', Ilim, 'w', dmmWires);
end

lastOutB = 0;
for i=1:N
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('%.0f%%.. ', 100.0*i/N);
    
    % Measure
    IV = ifaceDMM(dmmID1, 'voltage', V1(i));
    I1(i) = IV(1)*1e3; V1(i) = IV(2);
    if strlength(dev2)>0
        IV = ifaceDMM(dmmID2, 'voltage', V2(i));
        I2(i) = IV(1)*1e3; V2(i) = IV(2);
    end
    
    % Update plots
    plotH(1).XData = V1;
    if logscale > 0
        plotH(1).YData = abs(I1);
    else
        plotH(1).YData = I1;
    end
    if strlength(dev2)>0
        plotH(2).XData = V2;
        if logscale > 0
            plotH(2).YData = abs(I2);
        else
            plotH(2).YData = I2;
        end
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
print(savPath + savName + ".png", '-dpng');
save(savPath + savName + "_IV.mat", 'I1','V1', 'I2', 'V2', 'devs', 'die', 'measurement', 'Ilim', 'dmmWires', 'dmmID1', 'dmmID2');

