#!/usr/bin/env tclsh

#------------------------------CONFIG----------------------------------------------#
set user      USERNAME
set pass      PASSWORD
set id_file   CLIENT_ID_FILE
set pia_url   http://www.privateinternetaccess.com/vpninfo/port_forward_assignment
set trans_url TRANSMISSION_URL/transmission/rpc
set device    VPN_DEVICE
#------------------------------END CONFIG------------------------------------------#

package require http
package require json

#------------------------------Check Transmission----------------------------------#
#Fetch CSRF token first
set resp_token [http::geturl $trans_url]
set csrf [lindex [http::meta $resp_token] 3]
http::cleanup $resp_token

#Check if port is still open
set query {{"arguments": {},"method": "port-test"}}
set headers "X-Transmission-Session-Id $csrf"
set resp_token [http::geturl $trans_url -query $query -headers $headers]
set resp_data [json::json2dict [http::data $resp_token]]

#Exit if port is still open
set port_open [dict get [dict get $resp_data arguments] port-is-open]
if {$port_open} {
	puts "Port is still open"
	return
}
puts "Port is no longer open. Let's continue!"
http::cleanup $resp_token

#------------------------------Fetch Port------------------------------------------#
#Pull client id out of file
set fp [open $id_file r]
set file_data [read $fp]
close $fp
set client_id $file_data

#Make request
regexp {inet .*?(10\.[0-9]+\.[0-9]+\.[0-9]+)} [exec ifconfig $device] -> local_ip
set query [::http::formatQuery user $user pass $pass client_id $client_id \
		   local_ip $local_ip]
set resp [json::json2dict [http::data [http::geturl $pia_url -query $query]]]
set port [dict get $resp port]
puts "Fetched new port: $port"

#------------------------------Update Transmission---------------------------------#
set query "{\"arguments\": {\"peer-port\":$port},\"method\": \"session-set\"}"
set headers "X-Transmission-Session-Id $csrf"
set resp_token [http::geturl $trans_url -query $query  -headers $headers]
set resp_data [json::json2dict [http::data $resp_token]]
if {[dict get $resp_data result] eq {success}} {
	puts "Port successfully updated"
} else {
	puts "Failed to update port"
}