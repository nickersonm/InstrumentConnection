%% visaConn.m  MN 2018-04-25
% Acquires an existing VISA connection or creates a new one
%   Pass 'noopen' to avoid fopen(obj)
% Requirements:
%   - Specified resource exists and responds to a *IDN? query

function connObj = visaConn(VISAaddr, varargin)
    noOpen = (~isempty(varargin) && ischar(varargin{1}) && contains(varargin{1}, 'noopen'));
    connObj = instrfind('RsrcName', VISAaddr, 'Tag', '');
    if isempty(connObj) % Make object if it does not exist
        connObj = visa('NI', VISAaddr);
        if ~noOpen; fopen(connObj); end
    else % Reuse if it exists
        if (~isempty(find(strcmp(connObj.Status,'open'), 1)))   % Keep it open if it's already open
            connObj = connObj(strcmp(connObj.Status,'open'));
        else
            connObj = connObj(1);   % Reconnect if it's closed
            if ~noOpen; fopen(connObj); end
        end
    end
    connObj.Timeout = 2;    % Reasonably fast timeout
    
    % Try identification query to test connection
    if ~noOpen
        try
            ident = query(connObj, '*IDN?');
            if numel(ident) < 2
                error('Invalid *IDN? response: %s', ident);
            end
        catch exception
            if isempty(varargin)
                % Toggle state and try one more time
                fclose(connObj);
                connObj = visaConn(VISAaddr, exception);
            else
                rethrow(varargin{1});
            end
        end
    end

end
