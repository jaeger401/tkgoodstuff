# FvwmDebug (tkgoodstuff client)

proc FvwmDebugDoOnLoad {} {
    if [string match "" [info commands fvwm]] {
	TKGError "FvwmDebug client will not work unless fvwm starts\
tkgoodstuff as an fvwm module." exit
    }
}

proc FvwmDebugCreateWindow {} {
    uplevel {
	fvwm send $Fvwm(outid) "Style fvwmdebug Sticky"
	toplevel .fvwmdebug
	wm geometry .fvwmdebug +0+100
	set fvparams {pagex pagey npagex npagey maxpagex maxpagey desktop focus}
	pack [frame .fvwmdebug.simple -relief raised -bd 1] -fill x -anchor w
	pack [frame .fvwmdebug.simple.title1]
	pack [frame .fvwmdebug.simple.entries]
	foreach v  $fvparams {
	    pack [label .fvwmdebug.simple.title1.l$v -text $v -width 11] -side left
	    pack [label .fvwmdebug.simple.entries.e$v -textvariable FvwmW($v) \
		      -width 11 -background lightblue] -side left
	}
	set fparams1 {x y w h t npagex npagey iconic iconx icony iconw iconh}
	set fparams2 {flags windowname iconname resname resclass mapped}
	pack [frame .fvwmdebug.grid -relief raised -bd 1] -fill x -anchor w
	pack [frame .fvwmdebug.grid.title1] -anchor w
	pack [label .fvwmdebug.grid.title1.id -text ID -width 10] -side left
	foreach v $fparams1 {
	    pack [label .fvwmdebug.grid.title1.l$v -text $v -width 7] -side left
	}
	pack [frame .fvwmdebug.grid.title2] -anchor w
	pack [label .fvwmdebug.grid.title2.id -width 10] -side left
	foreach v $fparams2 {
	    pack [label .fvwmdebug.grid.title2.l$v -text $v -width 15 -foreground red] -side left
	}
	TKGAddToHook Fvwm_ConfigureWindow_hook FvwmDebug-wl-update
	set fevents1 {
	    AddWindow
	    ConfigureWindow
	    NewPage
	    NewDesk
	    WindowName
	    IconName
	}
	set fevents2 {
	    ResName
	    ResClass
	    DestroyWindow
	    FocusChange
	    Iconify
	    IconLocation
	    Deiconify
	    Map
	}
	pack [frame .fvwmdebug.numevents1 -relief raised -bd 1] -fill x
	foreach v $fevents1 {
	    set FvwmDebug-$v 0
	    set w .fvwmdebug.numevents1.[string tolower $v]
	    pack [frame $w] -expand y -fill x -side left
	    pack [label $w.name -text $v] -side top -expand n
	    pack [label $w.num -width 5 -textvariable FvwmDebug-$v \
		     -background lightblue] -side top -expand n
	    TKGAddToHook Fvwm_[set v]_hook FvwmDebug-update-$v
	    proc FvwmDebug-update-$v args [subst {
		global FvwmDebug-$v
		incr FvwmDebug-$v
	    }]
	}
	pack [frame .fvwmdebug.numevents2 -relief raised -bd 1] -fill x
	foreach v $fevents2 {
	    set FvwmDebug-$v 0
	    set w .fvwmdebug.numevents2.[string tolower $v]
	    pack [frame $w] -expand y -fill x -side left
	    pack [label $w.name -text $v] -side top -expand n
	    pack [label $w.num -width 5 -textvariable FvwmDebug-$v\
		     -background lightblue] -side top -expand n
	    TKGAddToHook Fvwm_[set v]_hook FvwmDebug-update-$v
	    proc FvwmDebug-update-$v args [subst {
		global FvwmDebug-$v
		incr FvwmDebug-$v
	    }]
	}
	TKGAddToHook Fvwm_DestroyWindow_hook FvwmDebug-destroy
    }
}

proc FvwmDebug-wl-update args {
    global FvwmW FvwmWL fparams1 fparams2
    if ![winfo exists .fvwmdebug] return
    foreach id [lsort [array names FvwmWL]] {
	set w .fvwmdebug.grid.w$id
	if ![winfo exists $w] {
	    pack [frame $w -relief raised -bd 2] -side top -anchor w
	    pack [label $w.l -text $id -width 10] -in $w -side left
	    pack [frame $w.w] -side left -in $w -anchor w
	    set w $w.w
	    pack [frame $w.w1] -side top -in $w -anchor w
	    foreach v $fparams1 {
		pack [label $w.w1e$v -textvariable FvwmW($id,$v) -width 7 -relief sunken\
			 -background lightblue] -in $w.w1 -side left
	    }
	    pack [frame $w.w2] -side top -anchor w
	    foreach v $fparams2 {
		pack [label $w.w1e$v -textvariable FvwmW($id,$v) -width 15 -relief sunken  -anchor w\
			  -foreground red -background lightblue] -in $w.w2 -side left
	    }
	}
    }
}

proc FvwmDebug-destroy {id} {
    if ![winfo exists .fvwmdebug] return
    .fvwmdebug.grid.w[set id].l configure -foreground gray30
}

DEBUG "Loaded FvwmDebug.tcl"
