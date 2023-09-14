%% [L]IV curve using two DMMs and reverse-biased SOA or PM
% Michael Nickerson 2022-07-19
%   Changed to strings 2023-07-27
clear;

%% Setup
% Record Parameters
die = "179.09AT";
dev = "0.05";
measurement = "soaLIV";

% Measurement Parameters
I = [linspace(0,30,10) linspace(30, 500, 20)]*1e-3;
Vlim = 10;    % Compliance voltage
endstate = "off";
direction = "ascend";
double = 1;

% Defaults
dmmID = 'GPIB16';
dmmIDsoa = 'GPIB26';
dmmWires = 2;
Vsoa = -2;  % SOA measurement bias
Ilimit = 10e-3; % SOA measurement current limit
avgT = 0.0;

% Allocate storage
I = sort(unique(I(:)), direction);
if double > 0
    I = [I; I(end:-1:1)];
end
N = numel(I);
V = NaN(size(I)); Isoa = V;


% Set up save names
savName = sprintf("%s_%s-%s_%s_%s", string(datetime("now", "Format", "yyyyMMdd")), ...
    die, dev, measurement, "T"+string(datetime("now", "Format", "hhmmss")));

savPath="C:\Users\IMPRESS Lab\LabShare\Measurements\ESI1030\";


%% Set up plot
[figH, axH, plotH] = plotStandard2D([I, V], 'y2', 'style', 'x', 'legend', 'Device', ...
                                    [I, Isoa], 'style', 'x', 'legend', 'SOA Excess Current', ...
                                    'fig', 2, 'legendloc', 'nw', ...
                                    'y2label', 'Bias [V]', ...
                                    'xlabel', 'Device Current [mA]', ...
                                    'ylabel', 'SOA Excess Current [mA]', ...
                                    'title', "[L]IV: "+ die +"-"+ dev);
set(gcf, 'CurrentCharacter', '_');


%% Run
% Initialize
ifaceDMM(dmmID, 'reset', 'avg', avgT, 'current', 1e-4, 'vlimit', Vlim, 'w', dmmWires, 'on');
ifaceDMM(dmmIDsoa, 'reset', 'avg', avgT, 'on', 'voltage', Vsoa, 'ilimit', Ilimit, 'w', dmmWires);
Isoa0 = ifaceDMM(dmmIDsoa); Isoa0 = Isoa0(1);

% Take voltage sweep
fprintf('Starting current sweep of %s.%s\n ', die, dev);
lastOutB = 0;
for i=1:N
    % Update progress
    fprintf(repmat('\b', [1 lastOutB]));
    lastOutB = fprintf('%.0f%%.. ', 100.0*i/N);
    
    % Measure
    IV = ifaceDMM(dmmID, 'current', I(i));
    I(i) = IV(1); V(i) = IV(2);
    IV = ifaceDMM(dmmIDsoa);
    Isoa(i) = IV(1);
    
    % Update plots
    set(plotH, 'XData', I*1e3);
    plotH(1).YData = V;
    plotH(2).YData = (Isoa-Isoa0)*1e3;
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
print(savPath + savName + ".png", '-dpng');
save(savPath + savName + "_IV.mat", 'I','V','Isoa','Isoa0','Vsoa','dev', 'die', 'measurement', 'Vlim', 'dmmWires', 'dmmID', 'dmmIDsoa');

