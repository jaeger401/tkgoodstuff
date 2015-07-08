proc setifunset { varname value } {    
    if ![uplevel [list info exists $varname]] {
	uplevel [list set $varname $value]
    }
}

# Is string $s empty?
proc Empty {s} {string match "" $s}

# Is string $i in the list $l?
proc In {i l} {expr [lsearch -exact $l $i] != -1}

proc ListAdd {listvar item} {
    upvar $listvar list
    if {![info exists list] 
	|| ![In $item $list]} {
	    lappend list $item
    }
    return $list
}

proc ListRemove {listvar item} {
    upvar $listvar list
    while {[set i [lsearch -exact $list $item]] != -1} {
	set list [lreplace $list $i $i]
    } 
    return $list
}

# Apply:  use: Apply command arglist
proc Apply args {
    foreach i $args { foreach j $i { lappend l $j } }
    uplevel 1 $l
}      

proc GetFile {f} {
    set id [open $f]
    set ret [read $id]
    close $id
    return $ret
}

proc Min args {
    set m [lindex $args 0]
    foreach a [lrange $args 1 end] {
	if $a<$m {set m $a}
    }
    return $m
}

proc Max args {
    set m [lindex $args 0]
    foreach a [lrange $args 1 end] {
	if $a>$m {set m $a}
    }
    return $m
}

proc TKGDoHook {hook args} {
    global $hook
    if ![info exists $hook] return
    foreach command [set $hook] {
	uplevel \#0 "eval $command $args"
    }
}

proc TKGAddToHook {hook args} {
    global $hook
    foreach arg $args {
	lappend $hook [list $arg]
    }
}

proc TKGRemoveFromHook {hook cmd} {
    global $hook
    if ![info exists $hook] return
    while {[set i [lsearch -exact [set $hook] [list $cmd]]] != -1} {
	set $hook [lreplace [set $hook] $i $i]
    }
}

proc TKGResetHook {hook} {
    global $hook
    catch {unset $hook}
}

proc TKGZeroTrim { s } {
    set o ""
    scan $s "%d" o
    return $o
}

# Replace @selection@ in string with X selection
proc SelectionSub {s} {
    if [catch {set sel [string trim [selection get]]}] {
	set sel ""
    }
    regsub -all -nocase @selection@ $s $sel s
    return $s
}

# TKGEncode and TKGDecode --
# Reversibly encode a string into a safe string (lowercase, no
# whitespace, backslashes, newlines, or dots).
proc TKGEncode {s} {
    regsub -all ~ $s ~~ s
    regsub -all { } $s ~s s
    regsub -all "\t" $s ~t s
    regsub -all "\n" $s ~n s
    regsub -all {\.} $s ~d s
    return $s
}

proc TKGDecode {s} {
    regsub -all ~~ $s ~ s
    regsub -all ~s $s { } s
    regsub -all ~t $s "\t" s
    regsub -all ~n $s "\n" s
    regsub -all ~d $s . s
    return $s
}

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

proc TKGCenter {w} {
    update idletasks
    set x [expr ([winfo vrootwidth $w] - [winfo reqwidth $w] )/2]
    set y [expr ([winfo vrootheight $w] - [winfo reqheight $w] )/2]
    wm geometry $w +$x+$y
    wm deiconify $w
}

proc ColorConfig { pathname fore back } {
    foreach child [winfo children $pathname] {
      ColorConfig $child $fore $back
    }
  if { "$fore" != "-" } { 
    catch "$pathname configure -foreground $fore"
  }
  if { "$back" != "-" } { 
    catch "$pathname configure -background $back"
  }
}

proc RecursiveBind { pathname seq command } {
    foreach window [winfo children $pathname] {
	RecursiveBind $window $seq $command
    }
    regsub -all @W $command $pathname c
    bind $pathname $seq $c
}

proc SetImage { name file } {
    global TKG
    if [regexp %(.*) $file file file] {
	set file ${file}$TKG(iconscale).xpm
    }    
    if [file exists $file] {
	set f $file 
    } else {
	foreach dir [split $TKG(icons) :] {
	    if [file exists $dir/$file] {
		set f $dir/$file
		break
	    }
	}
    }
    if ![info exists f] {
	TKGError "Can't locate image file $file." exit
    }
    foreach imagetype [image types] {
	if {! [catch { image create $imagetype $name -file $f }]} {
	    return $imagetype
	} 
    }
    TKGError "File $file does not contain an image we can parse." exit
}    

proc TKGGetPassword {title {message ""}} {
    set i 0
    while {[winfo exists .getpswd$i]} {incr i}
    set w .getpswd$i
    set v getpassword$i
    global $v
    TKGDialog getpswd$i \
	-title $title \
	-wmtitle $title \
	-image question \
	-nodismiss -nodeiconify\
    	-buttons [list \
		      [list abort "Abort" "set $v @@ABORT@@; destroy $w"] \
		      [list ok "OK" "destroy $w"]]
    if ![Empty $message] {
	grid [message $w.m -text $message] -row 1 -column 0 -sticky nsew
    }
    grid [frame $w.w] -row 2 -column 0 -sticky nsew
    grid columnconfigure $w.w 1 -weight 1
    grid [label $w.w.l2 -text "Password:"] \
	-row 1 -column 0 -sticky w
    set i 0
    grid [entry $w.w.e2 -textvariable $v -show *] \
	       -row 1 -column 1 -sticky we
    bind $w.w.e2 <Key-Return> [subst {
	$w.buttons.ok flash
	$w.buttons.ok invoke
    }]
    focus $w.w.e2
    TKGCenter $w
    tkwait window $w
    set password [set $v]
    unset $v
    return $password
}

# reset all grid row and column weights to 0
proc TKGClearWeights {w} {
    set size [grid size $w]
    for {set col 0} {$col < [lindex $size 0]} {incr col} {
	grid columnconfigure $w $col -weight 0
    }
    for {set row 0} {$row < [lindex $size 1]} {incr row} {
	grid rowconfigure $w $row -weight 0
    }
}

# takes percentage of normal settings (as in "xset q")
# we default to a higher than normal bell pitch
# but respect other parameters by default
proc TKGBell {{percent 1} {pitch {1.2}} {duration {1}}} {
    global TKG
    if $TKG(nobeep) return
    if {![info exists TKG(bell,pitch)]} {
	set TKG(bell,pitch) ""
	set TKG(bell,percent) ""
	set TKG(bell,duration) ""
	if [catch {
	    scan [exec xset q | grep bell ] \
		" %s %s %d %s %s %d %s %s %d "\
		x x TKG(bell,percent) \
		x x TKG(bell,pitch) \
		x x TKG(bell,duration)
	} err] {TKGNotice $err}
    }
    if {![Empty TKG(bell,pitch)]} {
	foreach param {percent pitch duration} {
	    set $param [expr int($TKG(bell,$param)*[set $param])]
	}
	if {$percent > 100} {set percent 100}
	exec xset b $percent $pitch $duration
    }
    bell
    if {![Empty TKG(bell,pitch)]} {
	exec xset b $TKG(bell,percent) $TKG(bell,pitch) $TKG(bell,duration)
    }
}

proc allAfterInfo {} {
    foreach id [after info] {
	lappend ret "[after info $id]\n"
    }
    return $ret
}