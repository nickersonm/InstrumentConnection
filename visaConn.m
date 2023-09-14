%% visaConn.m  MN 2018-04-25
% Acquires an existing VISA connection or creates a new one
% Requirements:
%   - Specified resource exists

function connObj = visaConn(VISAaddr)
    persistent visaMap;
    if isempty(visaMap)
        visaMap = struct();
    end
    
    if isstring(VISAaddr); VISAaddr = char(VISAaddr); end
    key = ['f' GetMD5(VISAaddr)];

    if isfield(visaMap, key)
        connObj = visaMap.(key);
    else
        visaMap.(key) = visadev(VISAaddr);
        connObj = visaMap.(key);
        connObj.Timeout = 1;    % Reasonably fast timeout
        % configureTerminator(connObj, 'LF', 'CR');
    end
end
