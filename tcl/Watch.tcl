# Watch (file-checking, viewing) Client Tcl code for tkgoodstuff

proc WatchDeclare {} {
    set Prefs_taborder(:Clients,Watch) "FileList Files Button Misc MH"
    set Prefs_taborder(:Clients,Watch,Button) "Misc Icons Colors Fvwm"
    TKGDeclare Watch(filelist) {} \
	-vartype watch -nolabel 1 -nodefault 1\
	-typelist [list Clients Watch FileList]
    TKGDeclare Watch(width) {120} \
	-typelist [list Clients Watch Misc]\
	-label "Width of viewer window (characters)."
    TKGDeclare Watch(height) {20} \
	-typelist [list Clients Watch Misc]\
	-label "Height of viewer window (lines)."
    TKGDeclare Watch(mheight) {10} \
	-typelist [list Clients Watch Misc]\
	-label "Height of viewer window (lines) when viewing multiple files."
    TKGDeclare Watch(viewfont) {} \
	-vartype font\
	-typelist [list Clients Watch Misc]\
	-label "Font in viewer"
    TKGDeclare Watch(viewer) {} \
	-typelist [list Clients Watch Misc]\
	-label "Command to launch  viewer (if not using tkgoodstuff's viewer)"
    ConfigDeclare Watch ClientButton1 Watch [list Clients Watch Button]
    ConfigDeclare Watch ClientButton2 Watch [list Clients Watch Button]
    ConfigDeclare Watch ClientButton5 Watch [list Clients Watch Button]
    TKGDeclare Watch(menufont) ""\
	-vartype font\
	-typelist [list Clients Watch Misc]\
	-label "Font for menu of files (when multiple files are used)"
    TKGDeclare Watch(tearoff) 0\
	-typelist [list Clients Watch Misc]\
	-vartype boolean\
	-label "Menu of files can be torn-off (when multiple files are used)"
    TKGDeclare Watch(usemenu) 0\
	-typelist [list Clients Watch Misc]\
	-vartype boolean\
	-label "Instead of usual button, include menu of files on panel"
    TKGDeclare Watch(unchanged_image) {%watchunchanged}\
	-typelist [list Clients Watch Button Icons]\
	-label "Icon for no change"
    set Watch(alertlevels) {white green yellow red}
    foreach level $Watch(alertlevels) {
	TKGDeclare Watch($level,image) "%watch$level"\
	    -typelist [list Clients Watch Button Icons]\
	    -label "Icon for change: $level alert"
    }

    TKGColorDeclare Watch(changedforeground) {#7fff00} \
	[list Clients Watch Button Colors] \
	"Button foreground: file changed"
    TKGColorDeclare Watch(changedbackground) {} \
	[list Clients Watch Button Colors] \
	"Button background: file changed" \
	$TKG(buttonbackground)
    TKGColorDeclare Watch(unchangedforeground) {} \
	[list Clients Watch Button Colors] \
	"Button foreground: file unchanged" \
        $TKG(buttonforeground)
    TKGColorDeclare Watch(unchangedbackground) {}\
	[list Clients Watch Button Colors] \
	"Button background: file unchanged" \
	$TKG(buttonbackground)
}

proc WatchUpdate {f} {
    global Watch TKG Watch_changed
    TKGPeriodicCancel WatchUpdate$f
    # When a monitoring window is open we slowly increase delay
    if {[incr Watch($f,delay) 1] > $Watch($f,update_interval)} {
	set Watch($f,delay) $Watch($f,update_interval)
    }
    switch [WatchatimeTest $f] {
	nochange {
	    TKGPeriodic WatchUpdate$f \
		$Watch($f,delay) $Watch($f,delay) "WatchUpdate $f"
	    return
	} 1 {
	    set Watch_changed($f) 1
	    set changed 1
	    Watch3MenuConfig $f 1
	    if {$Watch($f,tailing) || $Watch($f,multitailing)} {
		WatchTailGet $f
		WatchTailColorize $f 1
		set Watch($f,delay) 1
	    } elseif {$Watch($f,show) && !$TKG(nonotices)} { 
		WatchDoShow $f
	    }
	} 0 {
	    catch {unset Watch_changed($f)}
	    Watch3MenuConfig $f 0
	    WatchTailColorize $f
	}
    }
    WatchSetAlert
    if [info exists changed] {WatchChangedStuff $f}
    TKGPeriodic WatchUpdate$f \
	$Watch($f,delay) $Watch($f,delay) "WatchUpdate $f"
}

proc WatchSetAlert {} {
    global Watch Watch_changed Watch-params
    if $Watch(usemenu) return
    foreach level $Watch(alertlevels) {
	foreach mb [array names Watch_changed] {
	    if {$Watch($mb,alertlevel) == $level} {
		set highest $level
	    }
	}
    }
    if [info exists highest] {
	if ![In [image names] Watch_$highest] {
	    SetImage Watch_$highest $Watch($highest,image)
	}
	set Watch-params(image,changed) Watch_$highest
	TKGButton Watch -mode changed
    } else {
	if {[set Watch-params(mode)] != "unchanged" } {
	    TKGButton Watch -mode unchanged
	}
    }
}

proc WatchChangedStuff {f} {
    global TKG Watch
    if { ! ( $Watch($f,nobeep) || $TKG(nobeep) ) } {
	# percent, pitch, duration
	TKGBell \
	    1 \
	    [expr 2.0 + (.2*[lsearch $Watch(alertlevels) $Watch($f,alertlevel)])]\
	    1
    }
    if ![Empty $Watch($f,changedevent)] {
	eval exec $Watch($f,changedevent) &
    }
}

proc WatchIgnore {} {
    global Watch
    foreach f $Watch(files) { 
	WatchIgnoreFolder $f 
    }
    TKGButton Watch -mode unchanged
}

proc WatchIgnoreFolder {f} {
    global Watch Watch_changed
    WatchatimeIgnore $f
    catch {unset Watch_changed($f)}
    WatchSetAlert
    if [winfo exists .watch3menu] {
	Watch3MenuConfig $f 0
	WatchTailColorize $f
    }
}

proc Watch_1 {} {
    global Watch Watch-params
    foreach f $Watch(files) {
	WatchUpdate $f
    }
    switch [llength $Watch(files)] {
	0 {
	    TKGNotice "No files are being watched."
	} 1 {
	    WatchDoShow [lindex $Watch(files) 0]
	} default {
	    WatchDoShow
	}
    }
}

proc Watch_3 {x y} {
    global Watch Watch-params
    if {[llength $Watch(files)] < 2} {
	return
    } else {
	foreach f $Watch(files) {
	    WatchUpdate $f
	}
	[set Watch-params(pathname)] configure -state normal
	eval tk_popup .watch3menu [TKGPopupLocate .watch3menu $x $y]
	raise .watch3menu
	focus .watch3menu
    }
}

proc Watch3MenuConfig {f new} {
    if ![winfo exists .watch3menu] return
    global Watch
    if $new {
	.watch3menu entryconfigure \
	    [expr [lsearch $Watch(files) $f] + \
		 ($Watch(tearoff) && ! $Watch(usemenu))]\
	    -foreground $Watch(changedforeground) \
	    -activeforeground $Watch(changedforeground) \
	    -background $Watch(changedbackground) \
	    -activebackground $Watch(changedbackground) 
    } else {
	.watch3menu entryconfigure \
	    [expr [lsearch $Watch(files) $f] + \
		 ($Watch(tearoff) && ! $Watch(usemenu))]\
	    -foreground $Watch(unchangedforeground) \
	    -activeforeground $Watch(unchangedforeground)\
	    -background $Watch(unchangedbackground) \
	    -activebackground $Watch(unchangedbackground) 
    }
}

proc WatchExecViewer {} {
    global Watch
    if !$Watch(usemenu) {
	TKGbuttonInvoke [set Watch-params(pathname)]
    } else {
	exec $Watch(viewer) &
    }
}

proc WatchDoShow {{f {}}} {
    global Watch TKG Watch-params
    # Showing multiple files?
    if {[Empty $f]} {
	set multi 1
	set wmtitle "Watching files"
	set title "tkgoodstuff Watch"
	set stopproc WatchMultiTailStop
	set showfolders {}
	foreach folder $Watch(files) {
	    if $Watch($folder,include) {
		lappend showfolders $folder
	    }
	}
	set showfolders 
	set heightdim mheight
	set ww watch_multi_show
	set Watch(flaggedfolder) ""
    } else {
	# No; user prefers own lister?
	if {![Empty $Watch($f,show_instead)]} {
	    regsub -all -nocase @file@ $Watch($f,show_instead) \
		[TKGDecode $f] cmd
	    if {[string match "Tcl *" $cmd]} {
		after 0 [list eval [string range $cmd 4 end]]
	    } else {
		eval exec $cmd &
	    }
	    return
	} else {
	    set multi 0
	    set showfolders $f
	    set wmtitle "[TKGDecode $f] (Watching)"
	    set title "tkgoodstuff Watch: [TKGDecode $f]"
	    set stopproc WatchTailStop
	    set heightdim height
	    set ww watch_show_$f
	}
    }
    if {[Empty $Watch(viewfont)]} {
	set Watch(viewfont) tkgfixedbig
    }
    TKGDialog $ww \
	-image file \
	-wmtitle $wmtitle \
	-title $title \
	-nodismiss \
	-nodeiconify \
	-buttons [list \
		      [list rescan Rescan \
			   "WatchDoShow $f"\
			  ]\
		      [list dismiss Dismiss \
			   "$stopproc $f; destroy .$ww"\
		      ]
		 ]
    wm protocol .$ww WM_DELETE_WINDOW "$stopproc $f; destroy .$ww"
    set view .$ww.view
    grid [frame $view -bd 0 -highlightthickness 0]\
	-row 5 -column 0 -sticky nsew
    grid columnconfigure $view 0 -weight 1
    foreach folder $showfolders {
	grid rowconfigure $view [lindex [grid size $view] 1]\
	    -weight 1
	set w $view.w$folder
	frame $w -relief raised -bd 1 -highlightthickness 0
	grid columnconfigure $w 0 -weight 1
	grid rowconfigure $w 1 -weight 1
	text $w.text \
	    -font $Watch(viewfont)\
	    -width $TKG(dialogtextwidth) -height $TKG(dialogtextheight) \
	    -takefocus 0 -yscrollcommand "$w.scrollbar set" \
	    -relief sunken -borderwidth 2 -state disabled
	grid $w.text -row 1 -column 0 -padx 5 -pady 0 -sticky nsew
	scrollbar $w.scrollbar -command "$w.text yview"
	grid $w.scrollbar -row 1 -column 1 -sticky nsew -padx 5 -pady 0
	grid $w -sticky nsew
	$w.text configure -state disabled
	$w.text configure -width $Watch(width)
	$w.text configure -height $Watch($heightdim)
	if {!$multi} {
	    set Watch($folder,tailw) $w
	    set Watch($folder,tailing) 1
	} else {
	    grid [label $w.label -text [TKGDecode $folder] \
		      -font tkghugebold -anchor w] \
		-row 0 -sticky nsw -pady 0
	    bind $w.label <2> "WatchIgnoreFolder $folder"
	    TKGBalloonBind $w.label "Click with button 2 to reset."
	    set Watch($folder,multiw) $w
	    set Watch($folder,multitailing) 1
	} 
	set Watch($folder,delay) 1
	after 0 "
	    WatchUpdate $folder
	    WatchTailGet $folder
	    WatchTailColorize $folder
	"
    }
    TKGCenter .$ww
}

proc WatchTailGet {f} {
    global Watch Watch_changed
    if {[catch {
	set text \
	    [exec tail -$Watch($f,numlines) $Watch($f,filename)]
	set Watch($f,atime) [file atime $Watch($f,filename)]
    }]} {
	set text "      (((Error reading $Watch($f,filename).)))"
    }
    foreach var "Watch($f,tailw) Watch($f,multiw)" {
	if {[info exists $var] 
	    && [winfo exists [set w [set $var].text]]} {
	    $w configure -state normal
	    $w delete 1.0 end
	    $w insert end $text
	    $w see end
	    $w configure -state disabled
	}
    }
}

proc WatchTailStop {f} {
    global Watch
    set Watch($f,tailing) 0
    set Watch($f,delay) $Watch($f,update_interval)
}

proc WatchMultiTailStop {} {
    global Watch
    foreach f $Watch(files) {
	set Watch($f,multitailing) 0
    }
}

proc WatchTailColorize {f {flag 0}} {
    global Watch Watch_changed
    if {[info exists Watch($f,multiw)] &&
	[winfo exists $Watch($f,multiw)]} {
	set titlelabel $Watch($f,multiw).label
	if {[info exists Watch_changed($f)]} {
	    $titlelabel configure \
		-foreground $Watch($f,alertlevel)
	} else {
	    $titlelabel configure \
		-foreground black
	}
	if $flag {
	    if {![Empty [set ff $Watch(flaggedfolder)]]} {
		$Watch($ff,multiw).label configure -text [TKGDecode $ff]
	    }
	    $Watch($f,multiw).label configure -text \
		"[TKGDecode $f]                 (most recently changed)"
	    set Watch(flaggedfolder) $f
	}
    }
}

proc WatchCreateWindow {} {
    if [TKGReGrid Watch] return
    global Watch Watch-params TKG_labels TKG

    if {[string first ~ $Watch(filelist)] != -1 } {
	regsub -all ~ $Watch(files) [glob ~] Watch(filelist)
    }
    set Watch(files) ""
    foreach f $Watch(filelist) {
	lappend Watch(files) [TKGEncode [lindex $f 1]]
    }

    # Create menu first, since we might be using it instead of button
    if {[llength $Watch(files)] > 1} {
	if {[Empty $Watch(menufont)]} {
	    set menufont tkgmedium
	} else {
	    set menufont $Watch(menufont)
	}
	if {$Watch(usemenu)} {set type tearoff}
	menu .watch3menu -tearoff [expr $Watch(tearoff) && !$Watch(usemenu)]\
	    -background $TKG(buttonbackground)\
	    -activebackground $TKG(butactivebackground)\
	    -font $menufont
	set Watch(maxnamelen) 0
	foreach f $Watch(files) {
	    if {[string length $f] > $Watch(maxnamelen)} {
		set Watch(maxnamelen) [string length $f]
	    }
	}
	foreach f $Watch(files) {
	    .watch3menu add command \
		-label [TKGDecode $f]\
		-command "WatchDoShow $f"
	}
	if $Watch(usemenu) {
	    .watch3menu post 400 400
	    set w [winfo reqwidth .watch3menu]
	    set h [winfo reqheight .watch3menu]
	    TKGMakeSwallow Watch -width $w -height $h\
		-exec "Tcl " -windowname watch3menu -borderwidth 0
	    bind .watch3menu <ButtonRelease-2> {
		WatchIgnoreFolder [lindex $Watch(files) [.watch3menu index active]]
		break
	    }
	    bind .watch3menu <ButtonRelease-3> {break}
	    bind .watch3menu <ButtonRelease-1> {
		if {![string match none [.watch3menu index active]]} {
		    .watch3menu invoke active
		}
		grab release .watch3menu
		break
	    }
	    return
	}
    }

    if {$Watch(noicon) && !$Watch(nolabel)} {
	set noicon ""
	set newicon ""
    } else {
	SetImage Watch_unchanged_image $Watch(unchanged_image)
	SetImage Watch_changed_image $Watch(yellow,image)
	set noicon Watch_unchanged_image
	set newicon Watch_changed_image
    }
    if $Watch(nolabel) {
 	set notext ""
	set newtext ""
    } else {
	set notext Unchanged
	set newtext Changed
    }
    TKGMakeButton Watch \
        -text(unchanged) $notext \
	-balloon(unchanged) $notext \
	-image(unchanged) $noicon\
        -command(unchanged)  {Watch_1} \
	-foreground(unchanged) $Watch(unchangedforeground) \
	-activeforeground(unchanged) $Watch(unchangedforeground) \
	-background(unchanged) $Watch(unchangedbackground) \
        -text(changed) $newtext \
        -balloon(changed) $newtext \
	-image(changed) $newicon\
        -command(changed) {Watch_1} \
	-foreground(changed) $Watch(changedforeground) \
	-activeforeground(changed) $Watch(changedforeground) \
	-background(changed) $Watch(changedbackground) \
	-iconside $Watch(iconside)\
	-relief $Watch(relief)\
	-ignore $Watch(ignore)\
	-font(unchanged) $Watch(font)\
	-font(changed) $Watch(font)\
	-usebutton2 0\
	-staydown(changed) $Watch(staydown)\
	-staydown(unchanged) $Watch(staydown)\
	-trackwindow(changed) $Watch(trackwindow)\
	-trackwindow(unchanged) $Watch(trackwindow)\
	-windowname(unchanged) $Watch(windowname)\
	-windowname(changed) $Watch(windowname)\
	-mode unchanged
    bind [set Watch-params(pathname)] <2> WatchIgnore
    bind [set Watch-params(pathname)] <3> {Watch_3 %X %Y}
}

proc WatchFileDeclare {f} {
    global Watch Prefs_taborder
    set Prefs_taborder(:Clients,Watch,Files,[TKGDecode $f]) \
	"General Misc"
    TKGDeclare Watch($f,filename) "" \
	-typelist [list Clients Watch Files [TKGDecode $f] General] \
	-label "File to check (full pathname)"

    TKGDeclare Watch($f,update_interval) 60 \
        -typelist [list Clients Watch Files [TKGDecode $f] General] \
        -label "Check every __ seconds"

    TKGDeclare Watch($f,alertlevel) yellow\
	-typelist [list Clients Watch Files [TKGDecode $f] General]\
	-vartype optionMenu \
        -optionlist {white green yellow red}\
        -label "Alert level" \
	-help "This affects the color of the icon."

    TKGDeclare Watch($f,show) 0\
	-typelist [list Clients Watch Files [TKGDecode $f] Misc]\
	-vartype boolean\
	-label "Pop-up viewer when file is changed."

    TKGDeclare Watch($f,show_instead) ""\
	-typelist [list Clients Watch Files [TKGDecode $f] Misc]\
	-label "Unix command to execute instead of using tkgoodstuff's
viewer."\
	-help "For instance, you might start another viewer."

    TKGDeclare Watch($f,numlines) "200" \
	-typelist [list Clients Watch Files [TKGDecode $f] Misc]\
	-label "How many lines (maximum) to keep in the lister."

    TKGDeclare Watch($f,include) 1 -vartype boolean\
	-typelist [list Clients Watch Files [TKGDecode $f] Misc]\
	-label "Include this file in the multiple-file viewer."

    TKGDeclare Watch($f,changedevent) ""\
	-typelist [list Clients Watch Files [TKGDecode $f] Misc]\
	-label "Unix command executed each time file has been changed."

    TKGDeclare Watch($f,nobeep) 0\
	-typelist [list Clients Watch Files [TKGDecode $f] General]\
	-vartype boolean\
        -label "Don't beep"
}

proc WatchInit {} {
    global Watch
    set Watch(show_selbg) white
    TKGAddToHook TKG_alldone_hook WatchGetGoing
}

proc WatchGetGoing {} {
    global Watch TKG env
    foreach f $Watch(files) {
	WatchFileDeclare $f
	if {[Empty $Watch($f,filename)]} {
	    set Watch($f,filename) [TKGDecode $f]
	}
	WatchatimeFolderInit $f
	set Watch($f,delay) $Watch($f,update_interval)
	TKGPeriodic WatchUpdate$f \
	    $Watch($f,delay) $Watch($f,delay) "WatchUpdate $f"
	after 1000 WatchUpdate $f
    }
}

#Watch "atime" method: assume there's new mail if the file is nonempty and
#hasn't been accessed since last modification.

proc WatchatimeFolderInit {f} {
    global Watch
    set Watch($f,mtime) 0
    set Watch($f,atime) 0
    set Watch($f,tailing) 0
    set Watch($f,multitailing) 0
}

proc WatchatimeTest {f} {
    global Watch Watch-params
    set file $Watch($f,filename)
    if [catch {file stat $file a}] {
	return 0
    } elseif {($a(mtime) == $Watch($f,mtime)) && \
		  ($a(atime) == $Watch($f,atime))} {
	return nochange
    }
    set Watch($f,mtime) $a(mtime)
    set Watch($f,atime) $a(atime)
    if {(( $a(size) == 0) || ($a(mtime) < $a(atime)))} {
	set return 0
    } else {
	set return 1
    } 
    return $return
}

proc WatchatimeIgnore {f} {
    global Watch
    set file $Watch($f,filename)
    if [catch {file stat $file a}] return
    set Watch($f,mtime) $a(mtime)
    set Watch($f,atime) $a(atime)
}

DEBUG "Loaded Watch.tcl"
