package provide updUtility 1.0

namespace eval ::upd::Utility:: {
	namespace export processCmdInputs
}

proc ::upd::Utility::processCmdInputs {args num} {
	variable ::upd::CFG

	set ::upd::CFG(configs) [list debug]
	set ::upd::CFG(debug)   false

	if {[expr {$num % 2}] != 0} {
		puts "Invalid configs. Must provide config and value. Allowed configs are: $CFG(configs)"
		exit
	}

	foreach {arg value} $args {
		set argz [string range $arg 2 end]

		if {[lsearch $::upd::CFG(configs) $argz] < 0} {
			puts "Invalid config. Allowed configs are: $::upd::CFG(configs)"
			exit
		}

		set ::upd::CFG($argz) $value
	}
}