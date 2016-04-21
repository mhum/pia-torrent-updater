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

#------------------------------Setup Command Line Configs--------------------------#
set CFG(configs) [list debug]
set CFG(debug)   false

if {[expr {$argc % 2}] != 0} {
	puts "Invalid configs. Must provide config and value. Allowed configs are: $CFG(configs)"
	exit
}

foreach {arg value} $argv {
	set argz [string range $arg 2 end]

	if {[lsearch $CFG(configs) $argz] < 0} {
		puts "Invalid config. Allowed configs are: $CFG(configs)"
		exit
	}

	set CFG($argz) $value
}

#------------------------------Check Transmission----------------------------------#
#Fetch CSRF token first
if {$CFG(debug)} {
	puts "DEBUG: Connecting to transmission at: $trans_url"
}

set resp_token [http::geturl $trans_url]
set response [http::meta $resp_token]

if {$CFG(debug)} {
	puts "DEBUG: Response received:"
	puts "DEBUG: $response"
}

http::cleanup $resp_token

set csrf [lindex $response 3]

if {$csrf eq {}} {
	puts "Error: Unable to retrieve CSRF token"
	puts "Response Received: $response"
	return
}

if {$CFG(debug)} {
	puts "DEBUG: Retrieved CSRF token: $csrf"
}

#Check if port is still open
set query {{"arguments": {},"method": "port-test"}}
set headers "X-Transmission-Session-Id $csrf"

if {$CFG(debug)} {
	puts "DEBUG: Send query: $query"
	puts "DEBUG: With headers: $headers"
	puts "DEBUG: To $trans_url"
}

set resp_token [http::geturl $trans_url -query $query -headers $headers]
set resp_data [json::json2dict [http::data $resp_token]]
http::cleanup $resp_token

if {$CFG(debug)} {
	puts "DEBUG: Received: $resp_data"
}

#Exit if port is still open
set port_open [dict get [dict get $resp_data arguments] port-is-open]

if {$CFG(debug)} {
	puts "DEBUG: Port open: $port_open"
}

if {$port_open} {
	puts "Port is still open"
	return
}
puts "Port is no longer open. Let's continue!"

#------------------------------Fetch Port------------------------------------------#
#Pull client id out of file
if {$CFG(debug)} {
	puts "DEBUG: Read client id from: $id_file"
}

set fp [open $id_file r]
set file_data [read $fp]
close $fp
set client_id $file_data

if {$CFG(debug)} {
	puts "DEBUG: Client id: $client_id"
}

#Make request
if {$CFG(debug)} {
	puts "DEBUG: Run ifconfig for $device:"
	puts [exec ifconfig $device]
}
regexp {inet .*?(10\.[0-9]+\.[0-9]+\.[0-9]+)} [exec ifconfig $device] -> local_ip

if {$CFG(debug)} {
	puts "DEBUG: Found IP: $local_ip"
}

set query [::http::formatQuery user $user pass $pass client_id $client_id \
		   local_ip $local_ip]

if {$CFG(debug)} {
	puts "DEBUG: Format query to fetch port: $query"
	puts "DEBUG: Sending to: $pia_url"
}

set resp [json::json2dict [http::data [http::geturl $pia_url -query $query]]]

if {$CFG(debug)} {
	puts "DEBUG: Response:"
	puts "DEBUG: $response"
}

set port [dict get $resp port]
puts "Fetched new port: $port"

#------------------------------Update Transmission---------------------------------#
set query "{\"arguments\": {\"peer-port\":$port},\"method\": \"session-set\"}"
set headers "X-Transmission-Session-Id $csrf"

if {$CFG(debug)} {
	puts "DEBUG: Send request to Transmission"
	puts "DEBUG: Query: $query"
	puts "DEBUG: Headers: $headers"
}

set resp_token [http::geturl $trans_url -query $query  -headers $headers]
set resp_data [json::json2dict [http::data $resp_token]]

if {$CFG(debug)} {
	puts "DEBUG: Response:"
	puts "DEBUG: $resp_data"
}

if {[dict get $resp_data result] eq {success}} {
	puts "Port successfully updated"
} else {
	puts "Failed to update port"
}
