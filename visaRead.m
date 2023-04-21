%% visaRead.m  MN 2018-04-30
% Queries arbitrary command to specified VISA address
function results = visaRead(visaAddr, command)
visaObj = visaConn(visaAddr);

if ~contains(visaObj.Status, 'open')
    fopen(visaObj);
end

flushinput(visaObj);
results = query(visaObj, command);

end
