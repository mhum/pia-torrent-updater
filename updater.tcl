#!/usr/bin/env tclsh

#------------------------------CONFIG----------------------------------------------#
set pia_user       USERNAME
set pia_pass       PASSWORD
set id_file        CLIENT_ID_FILE
set device         VPN_DEVICE
set trans_rpc_url  TRANSMISSION_URL/transmission/rpc
set rpc_auth       RPC_TRUE/FALSE
set rpc_user       RPC_USERNAME
set rpc_pass       RPC_PASSWORD

set pia_url        http://www.privateinternetaccess.com/vpninfo/port_forward_assignment
#------------------------------END CONFIG------------------------------------------#

set auto_path [linsert $auto_path 0 .]

namespace eval ::upd:: {
	variable CFG

	set cfgs [list pia_user pia_pass id_file device trans_rpc_url rpc_auth rpc_user rpc_pass pia_url]

	foreach cfg $cfgs {
		set CFG($cfg) [expr $$cfg]
	}
}

package require updPia 1.0
package require updTransmission 1.0
package require updUtility 1.0

#------------------------------Setup Command Line Configs--------------------------#
::upd::Utility::processCmdInputs $argv $argc


#------------------------------Check Transmission----------------------------------#
::upd::updTransmission::checkPort

#------------------------------Fetch Port------------------------------------------#
set port [::upd::updPia::fetchPort]

#------------------------------Update Transmission---------------------------------#
::upd::updTransmission::setPort $port
