package provide updTransmission 1.0

package require base64
package require http
package require json

namespace eval ::upd::updTransmission:: {
	variable HEADERS [list]

	namespace export checkPort setPort
}

proc ::upd::updTransmission::checkPort {} {
	_fetchCsrf
	_checkPort
	puts "Port is no longer open. Let's continue!"
}

proc ::upd::updTransmission::setPort {port} {
	set query "{\"arguments\": {\"peer-port\":$port},\"method\": \"session-set\"}"

	set resp_data [_makeRequest $query "data"]

	if {[dict get $resp_data result] eq {success}} {
		puts "Port successfully updated"
	} else {
		puts "Failed to update port"
	}
}

proc _fetchCsrf {} {
	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Connecting to transmission at: $::upd::Utility::CFG(trans_rpc_url)"
	}

	if {$::upd::Utility::CFG(rpc_auth)} {
		set auth "Basic [base64::encode $::upd::Utility::CFG(rpc_user):$::upd::Utility::CFG(rpc_pass)]"

		set ::upd::updTransmission::HEADERS [list Authorization $auth]
	}

	set response [_makeRequest {} "meta"]

	set header [lindex $response 2]

	if {$header eq "WWW-Authenticate"} {
		puts "Error: RPC authentication required"
		exit
	}

	set csrf [lindex $response 3]

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Retrieved CSRF token: $csrf"
	}

	lappend ::upd::updTransmission::HEADERS X-Transmission-Session-Id $csrf

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Set headers: $::upd::updTransmission::HEADERS"
	}
}

proc _isPortOpen {} {
	set query {{"arguments": {},"method": "port-test"}}

	set resp_data [_makeRequest $query "data"]

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Received: $resp_data"
	}

	if {$resp_data eq 1} {
		puts "Error: RPC authentication failed"
		exit
	}

	#Exit if port is still open
	return [dict get [dict get $resp_data arguments] port-is-open]
}

proc _checkPort {} {
	#Exit if port is still open
	set port_open [_isPortOpen]

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Port open: $port_open"
	}

	if {$port_open} {
		puts "Port is still open"
		exit
	}
}

proc _makeRequest {query type} {
	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Send request to Transmission"
		puts "DEBUG: Query: $query"
		puts "DEBUG: Headers: $::upd::updTransmission::HEADERS"
	}

	set resp_data {}

	if {$type eq "data"} {
		set resp_token [http::geturl \
			$::upd::Utility::CFG(trans_rpc_url) \
			-query $query  \
			-headers $::upd::updTransmission::HEADERS \
		]
		set resp_data [json::json2dict [http::data $resp_token]]
	} elseif {$type eq "meta"} {
		set resp_token [http::geturl \
			$::upd::Utility::CFG(trans_rpc_url) \
			-headers $::upd::updTransmission::HEADERS \
		]

		set resp_data [http::meta $resp_token]
	}

	http::cleanup $resp_token

	if {$::upd::Utility::CFG(debug)} {
		puts "DEBUG: Response:"
		puts "DEBUG: $resp_data"
	}

	return $resp_data
}