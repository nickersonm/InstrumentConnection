%% Simple coupling optimization using DMM current
% Michael Nickerson 2020-08-18

%% Setup
% Piezo settings

piezoID = 'Station2right';
spanV = [10 10 5];  % Search ± around center
% spanV = [20 20 10];  % Search ± around center
tolV = spanV/5;

% DMM settings
dmmID = 'GPIB16';
dmmWires = 4;
Ilim = 10e-3;    % DMM compliance current
dmmV = -2;

% LDC settings
ldcID = 'Station2';
if ~exist('Ilaser', 'var')
%     Ilaser = 111e-3;    % ~10mW 980nm into lensed fiber in homodyne setup
%     Ilaser = 105e-3;    % ~3mW 1030nm into lensed fiber in homodyne setup
    Ilaser = 0; % Using external source
end

% Allocate storage
dV = tolV/2;
searchV = arrayfun(@(i) (-spanV(i):dV(i):spanV(i))', 1:numel(tolV), 'UniformOutput', 0);
V = searchV; I = cell(size(V)); L = I;

chs = mapPiezo(piezoID).channels;
centerV = ifacePiezo(piezoID);
Nch = numel(centerV);


%% Set up plot
allChs = {}; fitChs = {};
for ch=1:Nch
    
    allChs = [allChs { ...
        [V{ch}, NaN(size(V{ch}))], 'style', 'x', 'legend', chs{ch}} ];
    fitChs = [fitChs { ...
        [V{ch}, NaN(size(V{ch}))], 'style', ':'} ];
end
[figH, axH, plotH] = ...
    plotStandard2D(allChs, fitChs, ...
        'fig', 1, 'legendloc', 'north', 'legendor', 'horizontal', ...
        'xlabel', 'Piezo [V]', ...
        'ylabel', 'DMM Current [mA]', ...
        'title', ['Coupling Optimization, ' piezoID], 'size', [800 500]);


%% Run
set(figH, 'CurrentCharacter', '_');
fprintf('Starting coupling optimization\n ');
ifaceLDC(ldcID, 'current', Ilaser, 'state', 1);
ifaceDMM(dmmID, 'w', dmmWires, 'ilimit', Ilim, 'voltage', dmmV, 'avg', 0, 'on');

lastV = inf(size(centerV));
ch = 1; lastOutB = 0;
while any(abs(centerV - lastV) > tolV)
    lastV(ch) = centerV(ch);
    
    % Update search range
    V{ch} = centerV(ch) + searchV{ch};
    V{ch} = unique( min(100, max(0, V{ch})) );
    I{ch} = NaN(size(V{ch})); L{ch} = I{ch};
    
    % Update progress
    lastOutBV = 0;
    lastOutB = fprintf('Scanning %s: ', chs{ch});
    
    % Scan channel
    for i = 1:size(V{ch},1)
        % Set and measure
        ifacePiezo(piezoID, 'vch', chs{ch}, V{ch}(i) );
        if i==1; pause(0.5); end    % Longer when jumping to the first
%         V{ch}(i) = allV(ch);
        IV = ifaceDMM(dmmID);
        I{ch}(i) = IV(1)*1e3;
        
        fprintf(repmat('\b', [1 lastOutBV]));
        lastOutBV = fprintf('%.2f', V{ch}(i));
        
        % Update plot
        plotH(ch).XData = V{ch};
        plotH(ch).YData = I{ch};
%         plotH(ch + Nch).YData = L{ch};
        drawnow;
    
        % Check for abort
        if ~isvalid(figH) || ~strcmp('_', get(figH, 'CurrentCharacter'))
            disp('Keypress detected: aborting');
            break;
        end
    end
    
    % Check for abort
    if ~isvalid(figH) || ~strcmp('_', get(figH, 'CurrentCharacter'))
        disp('Keypress detected: aborting');
        break;
    end
    
    % Fit and plot
    fitObj = fit(V{ch}, I{ch}, 'SmoothingSpline', 'SmoothingParam', 0.25);
    fitV = (min(V{ch}):dV(ch)/4:max(V{ch}))';
    fitI = feval(fitObj, fitV);
    plotH(ch + Nch).XData = fitV;
    plotH(ch + Nch).YData = fitI;
    plotH(ch + Nch).Color = plotH(ch).Color; drawnow;
    
    % Go to max if reasonable
    [~, vI] = min(fitI);
    if (fitV(vI) > 10) && (fitV(vI) < 90)
        ifacePiezo(piezoID, 'vch', chs{ch}, fitV(vI));
    else
        warning('\nChannel %s fit was poor; going to center of range (%f)\n', chs{ch}, mean(fitV));
        ifacePiezo(piezoID, 'vch', chs{ch}, mean(fitV));
    end
    
    % Update center
    centerV(ch) = fitV(vI);
    
    fprintf(repmat('\b', [1 lastOutB + lastOutBV]));
    fprintf('%s = %.2f\n', chs{ch}, centerV(ch));
    
    % Next channel
    ch = mod(ch, Nch)+1;
end

% Reset to default
% ifaceDMM(dmmID, 'voltage', dmmV, 'avg', 0);

fprintf('  Completed %s: [%s]\n', piezoID, num2str(centerV, '%.2f,'));


%% Clean up
% ifaceLDC(ldcID, 'state', 0);
ifaceDMM(dmmID, 'voltage', dmmV, 'avg', 0, 'off');


%% Helper function
% Averages multiple y-values for identical x-values
function xy = bindata(x, y)
    [x, ~, xi] = uniquetol(x, 1e-3);
    y = accumarray(xi, y, [], @(x) mean(x, "omitnan"));
    xy = [x(:), y(:)];
end
