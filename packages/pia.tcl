package provide updPia 1.0

package require http

namespace eval ::upd::updPia:: {
	namespace export checkPort
}

proc ::upd::updPia::fetchPort {} {
	#Pull client id out of file
	if {$::upd::CFG(debug)} {
		puts "DEBUG: Read client id from: $::upd::CFG(id_file)"
	}

	set fp [open $::upd::CFG(id_file) r]
	set file_data [read $fp]
	close $fp
	set client_id $file_data

	if {$::upd::CFG(debug)} {
		puts "DEBUG: Client id: $client_id"
	}

	#Make request
	if {$::upd::CFG(debug)} {
		puts "DEBUG: Run ifconfig for $::upd::CFG(device):"
		puts [exec ifconfig $::upd::CFG(device)]
	}
	regexp {inet([\s\w]|[:])+(10\.[0-9]+\.[0-9]+\.[0-9]+)} [exec ifconfig $::upd::CFG(device)] -> space local_ip

	if {$::upd::CFG(debug)} {
		puts "DEBUG: Found IP: $local_ip"
	}

	set query [::http::formatQuery \
		user $::upd::CFG(pia_user) \
		pass $::upd::CFG(pia_pass) \
		client_id $client_id \
		local_ip $local_ip \
	]

	if {$::upd::CFG(debug)} {
		puts "DEBUG: Format query to fetch port: $query"
		puts "DEBUG: Sending to: $::upd::CFG(pia_url)"
	}

	set resp [json::json2dict [http::data [http::geturl $::upd::CFG(pia_url) -query $query]]]

	if {$::upd::CFG(debug)} {
		puts "DEBUG: Response:"
		puts "DEBUG: $resp"
	}

	set port [dict get $resp port]
	puts "Fetched new port: $port"

	return $port
}