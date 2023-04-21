%% Simple coupling optimization using DSO value
% Michael Nickerson 2020-08-18

%% Setup
% Piezo settings
piezoID = {'Station2right', 'Station2left'};
chs = {'yxz', 'xyz'};
spanV = [10 10 5];  % Search ± around center
tolV = spanV/5;

% LDC settings
ldcID = 'Station2';
if ~exist('Ilaser', 'var')
%     Ilaser = 111e-3;    % ~10mW 980nm into lensed fiber in homodyne setup
%     Ilaser = 105e-3;    % ~3mW 1030nm into lensed fiber in homodyne setup
    Ilaser = 0; % Using external source
end

% DSO settings
dsoID = 'Station2USB';
dsoCh = 4;

% Allocate storage
dV = tolV/2.5;
searchV = arrayfun(@(i) (-spanV(i):dV(i):spanV(i))', 1:numel(tolV), 'UniformOutput', 0);
V = searchV; L = cell(size(V));


%% Initialize
ifaceLDC(ldcID, 'current', Ilaser, 'state', 1); pause(1.0);


%% Iterate through piezo controllers
for pz = 1:numel(piezoID)
Nch = numel(chs{pz});
fprintf('Optimizing %s:\n', piezoID{pz});


%% Set up plot
allChs = {}; fitChs = {};
for ch=1:Nch
    allChs = [allChs { ...
        [V{ch}, NaN(size(V{ch}))], 'style', 'x', 'legend', chs{pz}(ch)} ];
    fitChs = [fitChs { ...
        [V{ch}, NaN(size(V{ch}))], 'style', ':'} ];
end
[figH, axH, plotH] = ...
    plotStandard2D(allChs, fitChs, ...
        'fig', 1, 'legendloc', 'south', 'legendor', 'horizontal', ...
        'xlabel', 'Piezo [V]', ...
        'ylabel', 'PD Voltage [arb]', ...
        'title', ['Coupling Optimization, ' piezoID{pz}], 'size', [800 500]);


%% Run
set(figH, 'CurrentCharacter', '_');

centerV = ifacePiezo(piezoID{pz});
centerV = centerV(arrayfun(@(c) find('xyz'==c), chs{pz}));    % Swap indicies
lastV = inf(size(centerV));
ch = 3; lastOutB = 0;
while any(abs(centerV - lastV) > tolV)
    lastV(ch) = centerV(ch);
    
    % Update search range
    V{ch} = centerV(ch) + searchV{ch};
    V{ch} = unique( min(100, max(0, V{ch})) );
    L{ch} = NaN(size(V{ch}));
    
    % Update progress
    lastOutBV = 0;
    lastOutB = fprintf('Scanning %s: ', chs{pz}(ch));
    
    % Scan channel
    for i = 1:size(V{ch},1)
        % Check for abort
        if ~isvalid(figH) || ~strcmp('_', get(figH, 'CurrentCharacter'))
            disp('Keypress detected: aborting');
            break;
        end
        
        % Set and measure
        ifacePiezo(piezoID{pz}, 'vch', chs{pz}(ch), V{ch}(i) );
        pause(0.01);
%         V{ch}(i) = allV(ch);
        L{ch}(i) = mean(dev_DSOgetTrace(dsoCh, mapDSO(dsoID).visaAddr, 1));
        
        fprintf(repmat('\b', [1 lastOutBV]));
        lastOutBV = fprintf('%.2f', V{ch}(i));
        
        % Update plot
        plotH(ch).XData = V{ch};
        plotH(ch).YData = L{ch};
        drawnow;
    end
    
    % Check for abort
    if ~isvalid(figH) || ~strcmp('_', get(figH, 'CurrentCharacter'))
        disp('Keypress detected: aborting');
        break;
    end
    
    % Fit and plot
    fitObj = fit(V{ch}, L{ch}, 'SmoothingSpline', 'SmoothingParam', 0.25);
    fitV = (min(V{ch}):dV(ch)/4:max(V{ch}))';
    fitL = feval(fitObj, fitV);
    plotH(ch + Nch).XData = fitV;
    plotH(ch + Nch).YData = fitL;
    plotH(ch + Nch).Color = plotH(ch).Color; drawnow;
    
    % Go to max if reasonable
    [~, vI] = max(fitL);
    if (fitV(vI) > 10) && (fitV(vI) < 90)
        % Apparently some backlash, as strange as that is for piezos
        ifacePiezo(piezoID{pz}, 'vch', chs{pz}(ch), fitV(vI)-10);
        pause(0.01);
        ifacePiezo(piezoID{pz}, 'vch', chs{pz}(ch), fitV(vI));
    else
        warning('\nChannel %s fit was poor; going to center of range (%f)\n', chs{pz}(ch), mean(fitV));
        % Apparently some backlash, as strange as that is for piezos
        ifacePiezo(piezoID{pz}, 'vch', chs{pz}(ch), mean(fitV)-10);
        pause(0.01);
        ifacePiezo(piezoID{pz}, 'vch', chs{pz}(ch), mean(fitV));
    end
    
    % Update center
    centerV(ch) = fitV(vI);
    
    fprintf(repmat('\b', [1 lastOutB + lastOutBV]));
    fprintf('%s = %.2f\n', chs{pz}(ch), centerV(ch));
    
    % Next channel
    ch = mod(ch, Nch)+1;
end

fprintf('  Completed %s: [%s]\n', piezoID{pz}, num2str(centerV, '%.2f,'));

end

disp('Coupling concluded.');


%% Clean up
% ifaceLDC(ldcID, 'state', 0);
