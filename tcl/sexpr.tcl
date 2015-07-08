# TKGSexpr --
# Parses an S-expression and returns a tcl list.
proc TKGSexpr {E} {
    set level 0
    for {set i 0} {$i < [string length $E]} {incr i} {
	switch -- [string index $E $i] {
	    ( {
		append L \{
	    } ) {
		append L \}
	    } " " {
		append L " "
	    } \" {
		set tmp ""
		while {[string comp [set c [string index $E [incr i]]] \"]} {
		    append tmp $c
		}
		append L "[list $tmp]"
	    } \{ {
		set n ""
		while {[string comp [set c [string index $E [incr i]]] \}]} {
		    append n $c
		}
		append L "[list [string range $E [expr $i + 3] [expr $i + $n + 2]]]"
		incr i [expr $n + 2]
	    } default {
		append L [list [string range $E $i [set i [ expr [string wordend $E $i] - 1]]]]
	    }
	}
    }
    return [lindex $L 0]
}
