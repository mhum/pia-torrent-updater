package provide updPia 1.0

package require http
package require tls

namespace eval ::upd::updPia:: {
	namespace export checkPort
}

proc ::upd::updPia::fetchPort {} {
	#Pull client id out of file
	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Read client id from: $::upd::Utility::CFG(id_file)"
	}

	set fp [open $::upd::Utility::CFG(id_file) r]
	set file_data [read $fp]
	close $fp
	set client_id [string trim $file_data]

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Client id: $client_id"
	}

	#Make request
	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Run ifconfig for $::upd::Utility::CFG(device):"
		puts [exec ifconfig $::upd::Utility::CFG(device)]
	}
	regexp {inet([\s\w]|[:])+(10\.[0-9]+\.[0-9]+\.[0-9]+)} \
		[exec ifconfig $::upd::Utility::CFG(device)] -> space local_ip

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Found IP: $local_ip"
	}

	set query [::http::formatQuery \
		user $::upd::Utility::CFG(pia_user) \
		pass $::upd::Utility::CFG(pia_pass) \
		client_id $client_id \
		local_ip $local_ip \
	]

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Format query to fetch port: $query"
		puts "DEBUG: Sending to: $::upd::Utility::CFG(pia_url)"
	}

	if {$::upd::Utility::CFG(pia_https)} {
		http::register https 443 [list ::tls::socket -tls1 1]
	}

	set resp [json::json2dict [http::data [http::geturl $::upd::Utility::CFG(pia_url) -query $query]]]

	if {$::upd::Utility::CFG(pia_https)} {
		http::unregister https
	}

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Response:"
		puts "DEBUG: $resp"
	}

	set port [dict get $resp port]
	puts "Fetched new port: $port"

	return $port
}