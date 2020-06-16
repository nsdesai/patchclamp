% MCTGCLIENT - communication with Multiclamp Commander (MCC)
%
%   CHAN = MCTGCLIENT('start') initiates communication with the MCC and
%   provides a list of available channels in the structure array CHAN.
%   Communication is established using the MCC telegraph server (MCTG),
%   which allows for reading MCC parameters using the Windows Messaging
%   Service (WMS).  MCTG requests are handled through WMS and do not
%   interfere with interactive control of the MCC program window.
%
%   The commands shown below cannot be called unless the 'start' command
%   has been issued.  The structure CHAN will contain one entry for each
%   device and channel connected to the server, is needed for the 'select'
%   program option, and will return [] if an error occurs.
%
%   FLAG = MCTGCLIENT('select', CHAN(INDEX)) selects the default channel
%   and device for reading telegraphs using the MCTG server.  The scalar
%   INDEX points to the entry in the structure CHAN returned by the 'start'
%   command to specify the device and channel.  The default channel is the
%   first device and channel found (INDEX = 1).  FLAG will return 0 if an
%   error occurs, 1 otherwise.
%
%   STRUCT = MCTGCLIENT('read') reads parameters from the selected device
%   and channel using the MCTG telegraph server and returns their values to
%   STRUCT.  MCTG parameters include scaled output, raw output and external
%   command gains.  The output STRUCT will return [] if an error occurs.
%
%   FLAG = MCTGCLIENT('stop') terminates MCTG communications through the
%   WMS and should be called before terminating program execution.  The
%   scalar FLAG will return 0 if an error occurs and returns 1 otherwise.

% 8/3/07 SCM
% MEX DLL
