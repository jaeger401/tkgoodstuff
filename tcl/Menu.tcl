# Menu Client Tcl code for tkgoodstuff
# format of menu: list of items:
# 0:type 1:label 2:list of switches 3:list of children for cascades

proc MenuDeclare {} {
    set Prefs_taborder(:Clients,Menu) "Menu Misc Button"
    TKGDeclare Menu(makebutton) 1 -typelist [list Clients Menu Button Misc]\
	-label "Produce a button (otherwise Menu 1 is bound to clock)"\
	-vartype boolean
    TKGDeclare Menu(text) "Menu" -typelist [list Clients Menu Button Misc]\
	-label "Text on button"
    TKGDeclare Menu(balloon) "" \
	-typelist [list Clients Menu Button Misc]\
	-label "Text of balloon help"
    TKGDeclare Menu(imagefile) {%tkgmenu} -typelist [list Clients Menu Button Misc]\
	-label "Image on Button (file)"
    TKGDeclare Menu(iconside) background -typelist [list Clients Menu Button Misc] \
	-label {Side of icon on button} -vartype optionMenu\
	-optionlist {left right top bottom background}
    TKGDeclare Menu(ignore)  1 \
	-label {Ignore general preferences for no labels and no icons} \
	-vartype boolean -typelist [list Clients Menu Button Misc]
    ConfigDeclare TkMan ClientButton1 TkMan [list Clients TkMan Button]
    TKGDeclare Menu(font) ""\
	-vartype font\
	-typelist [list Clients Menu Button Misc]\
	-label "Font on button" -help "Leave blank for a default that depends on the tkgoodstuff\
font scale."
    if [Empty $Menu(font)] {
#	set Menu(font) "Times [lindex {14 18 24} $TKG(fontscale)] bold"
	set Menu(font) tkghugebold
    }
    TKGDeclare Menu(tearoff) 0 -typelist [list Clients Menu Misc]\
	-label "Make tear-off menus" -vartype boolean
    ConfigDeclare Menu ClientButton3 Menu [list Clients Menu Button]
    set mdata [list \
      [list Menu Applications {} [list \
        [list Exec Rxvt [list -command rxvt]]\
	[list Exec Emacs [list -command emacs]]\
	[list Exec Knews [list -command knews]]\
	[list Exec Netscape [list -command netscape]]\
        [list Exec XV [list -command xv]]\
				     ]]\
      [list Separator "-------"]\
      [list Menu Utilities {} [list \
        [list Exec tkdesk]\
	[list Exec xdir]\
	[list Exec tkman]\
	[list Exec xfontsel]\
	[list Exec xcolorsel]\
	[list Exec "TkCon" [list -command tkcon.tcl]]\
				  ]]\
      [list Separator "-------"]\
      [list Run "Run . . ."]\
      [list Separator "-------"]\
      [list TKGMenu "tkgoodstuff Menu"]\
		   ]
    TKGDeclare Menu(data) $mdata\
	-typelist [list Clients Menu Menu]\
	-vartype menu -nolabel 1 -nodefault 1
    unset mdata
}

proc MenuCreateWindow {} {
    global MenuClient-params Menu
    if {![TKGReGrid MenuClient] && ![info exists Menu(current)]} {
	if $Menu(makebutton) {
	    lappend c TKGMakeButton MenuClient \
		-menu .menu\
		-foreground $Menu(foreground) \
		-background $Menu(background) \
		-activeforeground $Menu(activeforeground) \
		-activebackground $Menu(activebackground) \
		-font $Menu(font) -ignore $Menu(ignore)
	    foreach v {text imagefile balloon iconside} {
		if ![Empty $Menu($v)] {
		    lappend c -$v $Menu($v)
		}
	    }
	    eval $c
	    set button [set MenuClient-params(pathname)]
	    set Menu(current) $button.menu
	    menu $Menu(current) -tearoff $Menu(tearoff)
	    $button configure -menu $Menu(current)
	} else {
	    global Clock
	    set Clock(menu) .menu
	    set Menu(current) .menu
	}
	set Menu(counter) 0
	foreach item $Menu(data) {
	    Menu[lindex $item 0] $item
	}
    }
}

proc MenuMenu {item} {
    set label [lindex $item 1]
    global Menu
    set m $Menu(current).[incr Menu(counter)]
    menu $m -tearoff $Menu(tearoff)
    $Menu(current) add cascade -label $label -menu $m
    set Menu(parent,$m) $Menu(current)
    set Menu(current) $m
    foreach child [lindex $item 3] {
	Menu[lindex $child 0] $child
    }
    set Menu(current) $Menu(parent,$Menu(current))
}

proc MenuExec {item} {
    global Menu
    set label [lindex $item 1]
    set switches [lindex $item 2]
    set command [lindex $switches [expr [lsearch $switches -command] +1]]
    if {$command == ""} {set command  $label}
    set command [SelectionSub $command]
    $Menu(current) add command -label $label -command [list MenuDoExec $command]
}

proc MenuDoExec {command} {
    global Fvwm
    if {[info exists Fvwm(outid)] && [string match Fvwm* $command]} {
	lappend C fvwm send 0 "Module $command"
    } else {
	lappend C eval exec $command &
    }
    if [catch $C err] {
      error $err
    }
}

proc MenuTcl {item} {
    global Menu
    set label [lindex $item 1]
    set switches [lindex $item 2]
    set command [lindex $switches [expr [lsearch $switches -command] +1]]
    if {$command == ""} {set command $label}
    set command [SelectionSub $command]
    $Menu(current) add command -label $label -command $command
}

proc MenuRun {item} {
    global Menu
    $Menu(current) add command -label "Run . . ." -command TKGRun
}    

proc MenuTKGMenu {item} {
    global Menu
    set m $Menu(current).tkgpopup
    $Menu(current) add cascade -label "TkGoodStuff menu" \
	-menu $m
    menu $m -tearoff $Menu(tearoff) -postcommand "TKGMenuDup .tkgpopup $m"
} 

proc MenuSeparator {item} {
    global Menu
    $Menu(current) add separator
} 

proc TKGRun {} {
    TKGDialog tkgrun -wmtitle "Run . . ." -title "Run . . ."\
	-buttons [list [list ok OK {eval exec $TKGRun_command &;destroy .tkgrun}]]
    grid [entry .tkgrun.entry -width 40 -textvariable TKGRun_command]\
	-row 5 -column 0 -sticky nsew
    focus .tkgrun.entry
    bind .tkgrun.entry <Key-Return> {
	.tkgrun.buttons.ok flash
	.tkgrun.buttons.ok invoke
	break
    }
}

# a slightly modified version of tkMenuDup in tearoff.tcl
proc TKGMenuDup {src dst} {
    set cmd "$dst configure"
    foreach option [$src configure] {
	if {[llength $option] == 2} {
	    continue
	}
	lappend cmd [lindex $option 0] [lindex $option 4]
    }
    eval $cmd
    set last [$src index last]
    if {$last == "none"} {
	return
    }
    for {set i [$src cget -tearoff]} {$i <= $last} {incr i} {
	set cmd "$dst add [$src type $i]"
	foreach option [$src entryconfigure $i]  {
	    lappend cmd [lindex $option 0] [lindex $option 4]
	}
	eval $cmd
	if {[$src type $i] == "cascade"} {
	    tkMenuDup [$src entrycget $i -menu] $dst.m$i normal
	    $dst entryconfigure $i -menu $dst.m$i
	}
    }
    regsub -all . $src {\\&} quotedSrc
    regsub -all . $dst {\\&} quotedDst
    regsub -all $quotedSrc [bindtags $src] $dst x
    bindtags $dst $x
    foreach event [bind $src] {
	regsub -all $quotedSrc [bind $src $event] $dst x
	bind $dst $event $x
    }
}

DEBUG "Loaded Menu.tcl"
