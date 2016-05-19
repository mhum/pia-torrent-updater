# Private Internet Access Transmission Updater
This script will update the listening port for [Transmission](http://www.transmissionbt.com)
with the forwarding port for users of [Private Internet Access](https://www.privateinternetaccess.com).

## How It Works
There are three steps to this script. First, it makes a remote procedure call to Transmision to see if
the current listening port is still open. If it isn't, the script gathers the local ip address for the
VPN device, and makes a request to PIA with your user name, password, and client id for the current
forwarding port. Finally, another remote procedure call is made to Transmission to update the listening
port with the forwarding port sent back by PIA.

## Requirements
[Tcl](http://www.tcl.tk/software/tcltk) and [Tcllib](http://www.tcl.tk/software/tcllib) are the only two requirements. They come pre-installed on most *nix operating systems.

## Configuring
All configurations are made at the very top of the file in the `CONFIG` section.
```tcl
set pia_user       USERNAME
set pia_pass       PASSWORD
set id_file        CLIENT_ID_FILE
set device         VPN_DEVICE
set trans_rpc_url  TRANSMISSION_URL/transmission/rpc
set rpc_auth       RPC_TRUE/FALSE
set rpc_user       RPC_USERNAME
set rpc_pass       RPC_PASSWORD

set pia_url        http://www.privateinternetaccess.com/vpninfo/port_forward_assignment
```
```
USERNAME         ---PIA user name
PASSWORD         ---PIA password
CLIENT_ID_FILE   ---Path to file containing client id
VPN_DEVICE       ---Device name for VPN connection. Usually tun0. Run ifconfig to find out
TRANSMISSION_URL ---URL to transmission. If running on same box: http://localhost:9091
RPC_TRUE/FALSE   ---If rpc authenication is enabled for transmission. Set to true or false
RPC_USERNAME     ---Transmission rpc username
RPC_PASSWORD     ---Transmission rpc password
```

## Running
First, we need a file with the unique, constant client id. This will be sent with every PIA request.
> **OS X**:   head -n 100 /dev/urandom | md5 > ~/.pia_client_id
>
> **Linux**: head -n 100 /dev/urandom | md5sum | tr -d " -" > ~/.pia_client_id

Once the client id file is created and the configurations set, it is as easy as running: `tclsh updater.tcl`

or make it executable with `chmod u+x updater.tcl` and then run `./updater.tcl`

## Scheduling
It can even be setup to run as a cron job to completely automate this process. Something such as:
> @hourly /usr/local/bin/tclsh /scripts/updater.tcl

## Troubleshooting
If it doesn't work for some reason, the script can ran in a debugging mode by adding a flag when running:

`./updater.tcl --debug true`

The script communicates with Transmission via its RPC API. Specific Transmission RPC configs can be found [here](https://trac.transmissionbt.com/wiki/EditConfigFiles#RPC) and the RPC specs [here](https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt).
