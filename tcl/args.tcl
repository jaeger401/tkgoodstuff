proc TKGParseArgs {paramsvar arglist 
		   {simpleswitches {}} {modeswitches {}}
		   {errmsg something} } {
    upvar \#0 $paramsvar P
    setifunset P(modes) ""
    for { set i 0 } { $i < [llength $arglist] } {incr i 2} {
	set parsed 0
	foreach switch $simpleswitches {
	    set switch [lindex $switch 0]
	    if { [lindex $arglist $i] == "-$switch" } {
		set P($switch) [lindex $arglist [expr $i + 1]]
		set parsed 1
		set parsedswitches($switch) 1
		break
	    }
	}
	if $parsed continue
	foreach switch $modeswitches {
	    set switch [lindex $switch 0]
	    if [regexp -- "-$switch\\((.*)\\)" [lindex $arglist $i] whatever s] {
		set P($switch,$s) [lindex $arglist [expr $i + 1]]
		if {[lsearch P(modes) $s] == -1} {lappend P(modes) $s}
		set parsed 1
		set parsedswitches(${switch},$s) 1
	    }
	}
	if !$parsed  {
	    bgerror "Unknown switch to $errmsg: [lindex $arglist $i]"
	}
    }
    return [array get parsedswitches]
}

proc TKGSetSwitchDefaults {paramsvar switches {subst 1}} {
    upvar \#0 $paramsvar P
    foreach switch $switches {
	if {[llength $switch] > 1} {
	    if $subst {
		setifunset P([lindex $switch 0]) [uplevel {#0} "subst \{[lindex $switch 1]\}"]
	    } else {
		setifunset P([lindex $switch 0]) [lindex $switch 1]
	    }
	}
    }
}

proc TKGSetMSSwitchDefaults {paramsvar switches {modes {}} {subst 1}} {
    upvar \#0 $paramsvar P
    if [Empty $modes] {set modes $P(modes)}
    foreach switch $switches {
	foreach mode $modes {
	    if {[llength $switch] > 1} {
		if $subst {
		    setifunset P([lindex $switch 0],$mode) [uplevel {#0} "subst \"[lindex $switch 1]\""]
		} else {
		    setifunset P([lindex $switch 0],$mode) [lindex $switch 1]
		}
	    }
	}
    }
}

proc TKGGetArgs {type name} {
    upvar \#0 $type$name P
    global TKG
    set args ""
    foreach switch $TKG(switches,$type) {
	set var [lindex $switch 0]
	if [info exists P($var)] {
	    lappend args -$var $P($var)
	}
    }
    return $args
}

proc TKGGetArg {arg arglist} {
    lindex $arglist [expr [lsearch $arglist -$arg] + 1]
}
