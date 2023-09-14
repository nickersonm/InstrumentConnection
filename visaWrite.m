%% visaWrite.m  MN 2018-04-30
% Writes arbitrary command to specified VISA address
function visaWrite(visaAddr, command)
    visaObj = visaConn(visaAddr);
    
    if ~contains(visaObj.Status, 'open')
        fopen(visaObj);
    end
    
    fprintf(visaObj, command);
end
