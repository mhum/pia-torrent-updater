package provide updUtility 1.0

namespace eval ::upd::Utility:: {
	variable CFG

	namespace export processCmdInputs loadConfigs
}

proc ::upd::Utility::processCmdInputs {args num} {
	variable CFG

	set CFG(configs) [list debug config port_check]
	set CFG(debug)      false
	set CFG(config)     {}
	set CFG(port_check) 1

	if {[expr {$num % 2}] != 0} {
		puts "Invalid configs. Must provide config and value. Allowed configs are: $CFG(configs)"
		exit
	}

	foreach {arg value} $args {
		set argz [string range $arg 2 end]

		if {[lsearch $CFG(configs) $argz] < 0} {
			puts "Invalid config. Allowed configs are: $::upd::CFG(configs)"
			exit
		}

		set CFG($argz) $value
	}
}

proc ::upd::Utility::loadConfigs {} {
	variable CFG

	set file_name [expr [llength $CFG(config)] > 0 ? {$CFG(config)} : {{.config}}]
	set fp [open $file_name r]
	set file_data [read $fp]
	close $fp

	foreach {config value} $file_data {
		set CFG($config) $value
	}

	set CFG(pia_https) [regexp {^(https:.*)$} $CFG(pia_url)]

	if {$CFG(debug)} {
		parray CFG
	}
}