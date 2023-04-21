%% ifacePiezo.m  MN 2020-06-26
% Interface for piezo controllers
% 
% Requirements:
%   - VISA interface functions in path
%   - Equipment is connected
% 
% Usage: V = ifacePiezo(piezoID[, options])
%   Returns:
%     V: Current piezo voltage; size [<channels>, 1]
%
%   Parameters:
%     piezoID: LDC ID - see mapLDC('list') for available LDCs
%
%     Options:
%       'vch' | 'setch', %i, %f: Set channel %i to voltage %f
%       'v' | 'voltage' | 'set', %f: Set output voltage; size(%f) = [<channels>, 1]
%           or scalar to set all
%       'reset': Set all channels to half-point
%       'maxv' | 'vmax' | 'limit': Return the maximum output voltage
%
% TODO:
%   - Test and debug

function V = ifacePiezo(piezoID, varargin)
%% Defaults and magic numbers
V = [];


%% Look up piezo controller and set appropriate interface and properties
piezo = mapPiezo(piezoID);

% Interface function
if isempty(piezo.interface)
    error('Unsupported piezo type "%s" for piezo "%s"!', piezo.type, piezoID);
end

% Channel limits
chLim = [1 numel(piezo.channels)];
vLim = [0 piezo.interface(piezo.visaAddr, 'limit')];


%% Option parsing and execution
% Allow multiple inputs; set up ordered list of functions to execute 
executeList = {};

% Allow passing of cells of options
varargin = flatten(varargin);

% Parameter parsing
while ~isempty(varargin)
    arg = lower(varargin{1}); varargin(1) = [];
    switch arg
        case {'vch', 'setch'}
            ch = validateCh(varargin{1}, chLim); varargin(1) = [];
            setv = validateV(varargin{1}, vLim); varargin(1) = [];
            executeList{end+1} = ...
                {'set', ch, setv};
        case {'v', 'voltage', 'set'}
            setv = varargin{1}; varargin(1) = [];
            if numel(setv) == numel(piezo.channels)
                setv = arrayfun(@(v) validateV(v, vLim), setv);
            elseif numel(setv) > 1
                error('Neither scalar nor channel-sized (%i) voltage requested: %s', numel(piezo.channels), num2str(setv, '%f, '));
            end
            executeList{end+1} = ...
                {'setall', setv};
        case 'reset'
            executeList{end+1} = ...
                {'setall', max(vLim)/2};
        case {'maxv', 'vmax', 'limit', 'lim'}
            V = max(vLim);
        otherwise
            if ~isempty(arg)
                warning('Unexpected option "%s", ignoring', num2str(arg));
            end
    end
end


%% Helper functions
    function c = validateCh(ch, chLim)
        if ischar(ch)
            c = find(strcmpi(piezo.channels, ch));
        else
            c = round(ch);
        end
        if ~((c >= min(chLim)) && (c <= max(chLim)))
            error('Channel %s not valid!', ch);
        end
    end
    function V = validateV(V, vLim)
        V = double(V);
        if ~((V >= min(vLim)) && (V <= max(vLim)))
            error('Set voltage %.2f not valid; system max %.2f.', V, max(vLim));
        end
    end

    % Flatten a nested cell
    function flatCell = flatten(varargin)
        flatCell = {};
        for j=1:numel(varargin)
            if iscell(varargin{j})
                flatCell = [flatCell flatten(varargin{j}{:})];
            else
                flatCell = [flatCell varargin(j)];
            end
        end
        flatCell = flatCell( ~cellfun(@isempty, flatCell) );
    end


%% Execute in order
for args = executeList
    piezo.interface(piezo.visaAddr, args{1}{:});
end


%% Read present state
if isempty(V)
    V = piezo.interface(piezo.visaAddr, 'readall');
end


end
