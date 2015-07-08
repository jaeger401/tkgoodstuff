# Load client for tkgoodstuff

proc LoadDeclare {} {
    set Prefs_taborder(:Clients,Load) "Misc More"
    TKGDeclare Load(interval) 10 -typelist [list Clients Load Misc]\
	-label "How often to check the load (seconds)"
    TKGDeclare Load(nographics) 0 -typelist [list Clients Load Misc]\
	-label "Omit graphic display"\
	-vartype boolean
    TKGDeclare Load(nonumbers) 0 -typelist [list Clients Load Misc]\
	-label "Omit numeric display"\
	-vartype boolean
    TKGDeclare Load(nolabel) 0 -typelist [list Clients Load More]\
	-label "Omit text label"\
	-vartype boolean
    TKGDeclare Load(label) Load -typelist [list Clients Load More]\
	-label "Label text"
    TKGDeclare Load(minheight) 30 -typelist [list Clients Load More]\
	-label "Minimum height (in pixels) of graphic display"
    TKGDeclare Load(minwidth) 46 -typelist [list Clients Load More]\
	-label "Minimum width (in pixels) of graphic display"
    TKGDeclare Load(command) {xterm -T Top -e top} -typelist [list Clients Load Misc]\
	-label "Command that gives us the load"
    TKGDeclare Load(scale) 1 -typelist [list Clients Load Misc]\
	-label "The initial (and smallest as we autoscale) maximum load on the scale"
    TKGColorDeclare Load(background) {} [list Clients Load More]\
	"Color of background in graphic display" $TKG(buttonbackground)
}

proc LoadCreateWindow {} {
    global Load_window TKG_iconSide Load-params Load TKG
    TKGLabelBox Load
    $Load_window configure -background $Load(background)
    TKGRowCol $Load_window
    if { (!$TKG(labelsonly)) && (!$Load(nographics))}  {
	switch $TKG_iconSide(current) {
	    left {
		set crow 0; set ccol 0; set lrow 0; set lcol 1
		set labrow 1;set labcol 0; set numrow 0;set numcol 0
	    } right { 
		set crow 0; set ccol 1; set lrow 0; set lcol 0
		set labrow 1;set labcol 0; set numrow 0;set numcol 0
		grid columnconfigure $Load_window 0 -weight 0
		grid columnconfigure $Load_window 1 -weight 1
	    } top {
		set crow 0; set ccol 0; set lrow 1; set lcol 0
		set labrow 0;set labcol 0; set numrow 0;set numcol 1
	    } bottom {
		set crow 1; set ccol 0; set lrow 0; set lcol 0
		set labrow 0;set labcol 0; set numrow 0;set numcol 1
		grid rowconfigure $Load_window 0 -weight 0
		grid rowconfigure $Load_window 1 -weight 1
	    }
	}
	frame $Load_window.canframe -relief sunken -bd 1 \
	    -background $Load(background)
	grid $Load_window.canframe -row $crow -column $ccol -sticky nsew
	TKGRowCol $Load_window.canframe
	set w $Load_window.canframe.canvas
	canvas $w -width $Load(minwidth) -height $Load(minheight)\
	    -highlightthickness 0 
	grid $w -sticky nsew
	bind $w <Configure> [subst {
	    bind $w <Configure> {}
	    update idletasks
	    $w delete all
	    set Load(W) \[expr \[winfo width $w\] \]
	    if {\$Load(W) < $Load(minwidth)} {set Load(W) $Load(minwidth)}
	    set Load(H) \[expr \[winfo height $w\] \]
	    if {\$Load(H) < $Load(minheight)} {set Load(H) $Load(minheight)}
	    $w create rectangle 0 0 \$Load(W) \$Load(H) -fill $Load(background) -tags bg
	    TKGPeriodic load \$Load(interval) 0 LoadUpdate
	    set Load(T) 1
	    set Load(curscale) $Load(scale)
	} ]
    }
    if {(!$Load(nonumbers)) || (!$TKG(iconsonly)) || (!$Load(nolabel))}  {
	if ![info exists lrow] {
	    set lrow 0; set lcol 0
	    switch $TKG_iconSide(current) {
		left { set labrow 0; set labcol 1; set numrow 0; set numcol 0}
		right { set labrow 0; set labcol 0; set numrow 0; set numcol 1}
		top { set labrow 1; set labcol 0; set numrow 0; set numcol 0}
		bottom { set labrow 0; set labcol 0; set numrow 1; set numcol 0}
	    }
	}
	grid [frame $Load_window.txt -background $Load(background)] \
	    -row $lrow -column $lcol
	if !$Load(nonumbers)  {
	    set Load(Load) [GetLoad]
	    label $Load_window.txt.numbers -textvariable Load(Load) -bd 1 \
		-background $Load(background)
	    grid $Load_window.txt.numbers -row $numrow -column $numcol
	}
	if { (!$TKG(iconsonly)) && (!$Load(nolabel))}  {
	    label $Load_window.txt.combotext -text $Load(label) \
		-background $Load(background)
	    grid $Load_window.txt.combotext -row $labrow -column $labcol
	}
    }
    TKGGrid $Load_window
    catch {unset TKG(balloontext,$Load_window)}
    if ![Empty $Load(command)] {
	RecursiveBind $Load_window <ButtonRelease-1> \
	    "exec $Load(command) &"
	TKGBalloonBind $Load_window "Click to run\n$Load(command)"
    } else {
	TKGBalloonBind $Load_window "System Load"
    }
}

proc LoadSuspend {} {
    TKGPeriodicCancel load
}

proc GetLoad {} {    
    set s [exec uptime]
    string trim [lindex $s [expr [llength $s] - 3]] ,]
}

proc LoadInit {} {
    if [file readable /proc/loadavg] {
	proc GetLoad {} {
	    set id [open /proc/loadavg]
	    set s [read $id]
	    close $id
	    lindex $s 0
	}
    }
}

proc LoadUpdate {} {
    global Load Load_window
    set canvas $Load_window.canframe.canvas
    set Load(Load) [GetLoad]
    while {$Load(curscale) < $Load(Load)} {
	set Load(curscale) [expr $Load(curscale) * 2]
	$canvas scale scaleme 0 $Load(H) 1 .5
	$canvas create line \
	    0 [expr $Load(H)/2] $Load(W) [expr $Load(H)/2]\
	    -fill \#f81440 -tag tick -tags {tick scaleme}
    }
    set bbtick [lindex [$canvas bbox tick] 1]
    set bbload [lindex [$canvas bbox load] 1]
    if { ($bbload > $bbtick) && ($Load(curscale) > $Load(scale)) } {
	set Load(curscale) [expr $Load(curscale) / 2]
	$canvas addtag deleteme closest 0 [expr $Load(H)/2]
	$canvas delete deleteme
	$canvas scale scaleme 0 $Load(H) 1 2
    }	
    set Load(L) [expr $Load(H) - 1 - (($Load(H) * $Load(Load))/$Load(curscale))]
    $canvas create line $Load(T) $Load(H) $Load(T) $Load(L) -tags {load scaleme}
    $canvas raise tick
    incr Load(T)
    if {$Load(T) == $Load(W)} {
	$canvas addtag deleteme closest 1 $Load(H)
	$canvas delete deleteme
	$canvas move load -1 0
	incr Load(T) -1
    }
}

