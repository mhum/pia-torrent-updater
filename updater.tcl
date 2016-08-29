#!/usr/bin/env tclsh

set auto_path [linsert $auto_path 0 .]

package require updPia 1.0
package require updTransmission 1.0
package require updUtility 1.0

#------------------------------Setup Command Line Configs--------------------------#
::upd::Utility::processCmdInputs $argv $argc

#------------------------------Load Configs From File------------------------------#
::upd::Utility::loadConfigs

#------------------------------Check Transmission----------------------------------#
::upd::updTransmission::checkPort

#------------------------------Fetch Port------------------------------------------#
set port [::upd::updPia::fetchPort]

#------------------------------Update Transmission---------------------------------#
::upd::updTransmission::setPort $port
