proc Strings {client label pairs} {
    global TKG_labels [set client]_strings [set client]_strings_set
    setifunset TKG_labels($client) $label
    for {set i 1} {$i < [llength $pairs]} {incr i 2} {
	setifunset [set client]_strings([lindex $pairs [expr $i - 1]])\
	       [lindex $pairs $i]
    }
    set [set client]_strings_set 1
}

proc TKGClientStrings {client} {
    global TKG [set client]_strings_set
    if [info exists [set client]_strings_set] return
    set l1 [set client]_language
    set l2 [set client]_default_language
    global $l1 $l2
    if ![info exists $l1] { set $l1 $TKG(language) }
    if {![info exists $l2]} { set $l2 english }
    if { ([set $l1] != [set $l2])\
	     && [file exists\
		     $TKG(libdir)/tcl/[set client]_[set $l1].tcl] } {
	source $TKG(libdir)/tcl/[set client]_[set $l1].tcl
    } else {
	[set client]_set_default_strings
    }
}

