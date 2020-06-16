% MCCMSGCLIENT - communication with Multiclamp Commander (MCC)
%
%   CHAN = MCCMSGCLIENT('start') initiates communication with the MCC and
%   provides a list of available channels in the structure array CHAN.
%   Communication is established using a MCC message server (MCCMSG) which
%   allows for direct control of the MCC program window.  Note that these
%   commands use the MCCMSG and give temporary control of the MCC program
%   window to this program.  This will interfere with interactive control
%   of the MCC program window.
%
%   The commands shown below cannot be called unless the 'start' command
%   has been issued.  The structure CHAN will contain one entry for each
%   device and channel connected to the server, is needed for the 'select'
%   program option, and will return [] if an error occurs.
%
%   FLAG = MCCMSGCLIENT('select', CHAN(INDEX)) selects the default channel
%   and device for reading telegraphs and changing modes using the MCCMSG
%   server.  The scalar INDEX points to the entry in the structure CHAN
%   returned by the 'start' command to specify the device and channel. 
%   The default channel is the first device and channel found (INDEX = 1).
%   FLAG will return 0 if an error occurs, 1 otherwise.
%
%   STRUCT = MCCMSGCLIENT('read') reads parameters from the selected
%   device and channel using the MCCMSG server and returns their values to
%   STRUCT.  MCCMSG parameters include holding, offset and compensation
%   parameters.  The output STRUCT will return [] if an error occurs.
%
%   FLAG = MCCMSGCLIENT('mode', MODE) changes the mode of the selected
%   device and channel to MODE = 'V-Clamp', 'I-Clamp' or 'I = 0' using the 
%   MCCMSG server.  FLAG will return 0 if an error occurred, 1 otherwise.
%
%   FLAG = MCCMSGCLIENT('stop') disconnects from the MCCMSG server and
%   should be called before terminating program execution.  The scalar
%   FLAG will return 0 if an error occurs and returns 1 otherwise.

%   Future versions can add calls to provide further control of the MCC
%   program, including setting pipette offset, running seal tests, and auto
%   compensation for pipette, whole cell and series resistance.

% 8/3/07 SCM
% MEX DLL
