# Jots Client Tcl code for tkgoodstuff

proc JotsDeclare {} {
    set Prefs_taborder(:Clients,Jots) "Misc Geometry Button Colors"
    set Prefs_taborder(:Clients,Jots,Button) "Misc Colors"
    TKGDeclare Jots(dir) {$env(HOME)/.tkgjots} -typelist [list Clients Jots Misc]\
	-label "Your Jots Directory" 
    TKGDeclare Jots(startwithnew) 0 -typelist [list Clients Jots Misc]\
	-label "Create new item when opening a folder"\
	-vartype boolean
    TKGDeclare Jots(lines) 20 -typelist [list Clients Jots Geometry]\
	-label "Height of text screen (lines)"
    TKGDeclare Jots(columns) 60 -typelist [list Clients Jots Geometry]\
	-label "Width of text screen (characters)"
    TKGDeclare Jots(showfindtool) 0 -typelist [list Clients Jots Misc]\
	-label "Show Find tool at startup"\
	-vartype boolean
    TKGDeclare Jots(showhotlist) 1 -typelist [list Clients Jots Misc]\
	-label "Show HotList at startup"\
	-vartype boolean
    TKGColorDeclare Jots(hots_cur_bg) \#87ceff [list Clients Jots Colors]\
	"HotList button background for current folder"
    TKGColorDeclare Jots(hots_cur_fg) {} [list Clients Jots Colors]\
	"HotList button foreground for current folder" $TKG(foreground)
    TKGDeclare Jots(makebutton) 1 -typelist [list Clients Jots Button Misc]\
	-label "Produce a button"\
	-vartype boolean
    TKGDeclare Jots(text) Jots -typelist [list Clients Jots Button Misc]\
	-label "Label text"
    TKGDeclare Jots(imagefile) %jots\
	-typelist [list Clients Jots Button Misc] -label "Icon file"
    ConfigDeclare Jots ClientButton1 Jots [list Clients Jots Button]
    ConfigDeclare Jots ClientButton3 Jots [list Clients Jots Button]
}

proc JotsCreateWindow {} {
    if [TKGReGrid JotsButton] return
    uplevel {
	set Jots(hotfile) "$Jots(dir)/.hotjots"
	set Jots(hots_cur_abg) $Jots(hots_cur_bg)
	set Jots(hots_cur_afg) $Jots(hots_cur_fg)
    }
    global Jots
    if $Jots(makebutton) {
	lappend c TKGMakeButton JotsButton -balloon {Jots notecard manager}
	foreach switch {
	    iconside ignore font imagefile text foreground background
	    activeforeground activebackground relief
	} {
	    lappend c -$switch $Jots($switch)
	}
	set w [eval $c]
	bind $w <1> +JotsPopup
    } else {
	TKGAddToHook TKG_clientwindowscreated_hook \
	    {if { [lsearch $TKG(clients) Clock ] != -1 } {
		RecursiveBind [set Clock_window] <3> {JotsPopup}
	    }}
    }
}

proc JotsPopup {} {
    global Jots env
    if $Jots(makebutton) {
	upvar #0 JotsButton-params P
	if ![string match [$P(pathname) cget -relief] sunken] {
	    $P(pathname) configure -relief sunken
	}
    }
    
    set Jots(index) 0
    set Jots(selectfolders) 1
    set Jots(edited) -1
    set Jots(openfolders) ""
    
    set w .jots
    if [winfo exists $w] {
	wm deiconify $w
	focus $w
	raise $w
	return
    }
    toplevel $w
    wm withdraw $w
    wm title $w "Jots"
    wm iconname $w "Jots"
    wm protocol $w WM_DELETE_WINDOW JotsFinalExit 
    
    frame $w.menu -relief raised -bd 2
    grid columnconfigure $w 0 -weight 1
    grid $w.menu -sticky ew -row 0 -column 0
#    pack $w.menu -side top -fill x
    
    set m $w.menu.file.m
    menubutton $w.menu.file -text "File" -menu $m
    menu $m
    $m add command -label "Open folder" -command JotsOpen
    $m add command -label "New folder" -command JotsNew
    $m add command -label "Merge into current folder" -command JotsMerge
    $m add cascade -label "Go to open folder" -menu  .jots.menu.file.m.openfolders
    menu .jots.menu.file.m.openfolders
    $m add separator
    $m add command -label "Save current folder" -command JotsSave
    $m add command -label "Save current folder as ..." -command JotsSaveAs
    $m add command -label "Save to ascii file ..." -command JotsSaveAscii
    $m add separator
    $m add command -label "Close current folder ..." -command JotsClose
    $m add command -label "Delete current folder ..." -command JotsDeleteFolder
    $m add separator
    $m add command -label "Exit ..." -command "JotsExit"

    set m $w.menu.hotlist.m
    menubutton $w.menu.hotlist -text "Hotlist" -menu $m
    menu $m
    $m add command -label "Add folder to hot list" -command JotsAddHot
    $m add command -label "Remove folder from hot list" -command JotsRemoveHot
    $m add separator
    
    set m $w.menu.edit.m
    menubutton $w.menu.edit -text "Edit" -menu $m
    menu $m
    $m add command -label "Cut Entry" -command JotsCut
    $m add command -label "Copy Entry" -command JotsCopy
    $m add command -label "Paste" -command JotsPaste
    
    set m $w.menu.find.m
    menubutton $w.menu.find -text "Find" -menu $m
    menu $m
    $m add checkbutton -label "Show Find Tool" -variable Jots(showfindtool)
    trace variable Jots(showfindtool) w JotsPackFind
    $m add separator
    
    pack $w.menu.file $w.menu.edit $w.menu.find $w.menu.hotlist -side left
    
    set m $w.menu.help.m
    menubutton $w.menu.help -text "Help" -menu $m
    menu $m
    $m add command -label "About Jots" -command JotsAbout
    $m add separator
    $m add command -label "Help" -command JotsHelp
    
    pack $w.menu.help -side right
    
    frame $w.hots
#    pack $w.hots -side top -fill x  -padx .1c -pady .1c -expand n
    grid $w.hots -row 1 -column 0 -sticky ew  -padx .1c -pady .1c
    set Jots(hotswindow) $w.hots
    
    grid rowconfigure $w 2 -weight 1
    frame $w.middle 
    grid rowconfigure $w.middle 0 -weight 1
    grid columnconfigure $w.middle 0 -weight 1
    
    set ww $w.middle.jotsentry 
    frame $ww -relief sunken -bd 3
    grid columnconfigure $ww 0 -weight 1
    grid rowconfigure $ww 0 -weight 1
    frame $ww.view
    grid columnconfigure $ww.view 0 -weight 1
    grid rowconfigure $ww.view 0 -weight 1
    text $ww.view.text -width $Jots(columns) -height $Jots(lines)\
	-takefocus 0 -yscrollcommand "$ww.view.scrollbar set" \
	-relief sunken -borderwidth 2 -state disabled -wrap word
    set Jots(textwindow) $ww.view.text
    grid $ww.view.text -row 0 -column 0 -sticky nsew
    scrollbar $ww.view.scrollbar -command "$ww.view.text yview"
    grid $ww.view.scrollbar -row 0 -column 1 -sticky nsew -padx 2
    $ww.view.text configure -state normal
    grid $ww.view -row 0 -column 0 -sticky nsew -pady .3c -padx .3c
    
    frame $ww.indices
    foreach i {0 1 2} {
	grid columnconfigure $ww.indices $i -weight 1
    }
    frame $ww.indices.jots_folder
    grid columnconfigure $ww.indices.jots_folder 1 -weight 1
    label $ww.indices.jots_folder.jots_folderlabel -text Folder:
    grid $ww.indices.jots_folder.jots_folderlabel -row 0 -column 0
    entry $ww.indices.jots_folder.jots_folderentry \
	-textvariable Jots(folder) -takefocus 0 -state disabled -relief flat
    grid $ww.indices.jots_folder.jots_folderentry -row 0 -column 1 -sticky ew
    frame $ww.indices.jots_date
    grid columnconfigure $ww.indices.jots_date 1 -weight 1
    label $ww.indices.jots_date.jots_datelabel -text Date:
    grid $ww.indices.jots_date.jots_datelabel -row 0 -column 0
    entry $ww.indices.jots_date.jots_dateentry\
	-textvariable Jots(date) -width 18 -takefocus 0 -state disabled -relief flat
    grid $ww.indices.jots_date.jots_dateentry -row 0 -column 1 -sticky ew
    frame $ww.indices.jots_time
    grid columnconfigure $ww.indices.jots_time 1 -weight 1
    label $ww.indices.jots_time.jots_timelabel -text Time:
    grid $ww.indices.jots_time.jots_timelabel -row 0 -column 0
    entry $ww.indices.jots_time.jots_timeentry \
	-textvariable Jots(time) -width 5 -takefocus 0 -state disabled -relief flat
    grid $ww.indices.jots_time.jots_timeentry -row 0 -column 1 -sticky ew
    $ww.indices.jots_folder.jots_folderentry configure -background [$ww.view cget -background]
    $ww.indices.jots_date.jots_dateentry configure -background [$ww.view cget -background]
    $ww.indices.jots_time.jots_timeentry configure -background [$ww.view cget -background]
    
    grid $ww.indices.jots_folder $ww.indices.jots_date $ww.indices.jots_time\
	-row 0 -sticky ew -padx .2c -pady .1c
    grid $ww.indices -row 1 -column 0 -sticky ew
    grid $ww -row 0 -column 0 -sticky nsew
    
    grid $w.middle -row 2 -column 0 -sticky nsew -padx .3c -pady .2c
    
    scrollbar $w.scroll -orient horizontal -command "JotsScroll" \
	-width .7c
    grid $w.scroll -row 3 -column 0 -sticky ew -pady .3c -padx .3c
    set Jots(SB) $w.scroll
    trace variable Jots(index) w JotsSUpdate

    frame $w.buttons
    button $w.buttons.new -command JotsNewEntry  -text "New\nEntry"
    pack $w.buttons.new -side left -expand y -fill y -padx .4c -pady .4c
    button $w.buttons.del -command JotsCut  -text "Delete\nEntry"
    pack $w.buttons.del -side left -expand y -fill y -padx .4c -pady .4c
    button $w.buttons.prev -command JotsPrev  -text "Previous\nEntry"
    pack $w.buttons.prev -side left -expand y -fill y -padx .4c -pady .4c
    button $w.buttons.next -command JotsNext  -text "Next\nEntry"
    pack $w.buttons.next -side left -expand y -fill y -padx .4c -pady .4c
    button $w.buttons.dismiss -text "Save All\nand Exit"\
	-command JotsDismiss
    pack $w.buttons.dismiss -side left -expand y -fill y -padx .4c -pady .4c
    grid $w.buttons -row 5 -sticky ew

    bind $Jots(textwindow) <Key> {set Jots(edited) $Jots(index)}
    bind $Jots(textwindow) <Button> {set Jots(edited) $Jots(index)}
    RecursiveBind $w <Meta-s> {JotsSave;break}
    RecursiveBind $w <Meta-q> {JotsDismiss;break}
    RecursiveBind $w <Meta-x> {JotsDismiss;break}
    RecursiveBind $w <Shift-Right> {JotsNext;break}
    RecursiveBind $w <Shift-Left> {JotsPrev;break}
    RecursiveBind $w <Shift-Meta-D> {JotsCut;break}
    RecursiveBind $w <Shift-Meta-N> {JotsNewEntry;break}

    JotsDirInit
}

######################################
#  File handling routines
######################################

proc JotsDirInit {} {
    global Jots
    set Jots(oldcwd) [pwd]
    if [file exists $Jots(dir)] {
	if ![file isdirectory $Jots(dir)] {
	    TKGError "$Jots(dir) (selected as your Jots directory) is not a directory"
	    JotsExit
	    return
	}
	if { ![file readable $Jots(dir)] || 
	     ![file writable $Jots(dir)] || 
	     ![file executable $Jots(dir)] } {
	    if [file owned $Jots(dir)] {
		if [catch "exec chmod u+rwx $Jots(dir)" err ] {
		    TKGError "Can't set permissions on \"$Jots(dir)\" (selected\
as your Jots directory): $err"
		    JotsExit
		    return
		}
		JotsDirOpen
	    } else {
		TKGError "You have inadequate permissions for\
 directory \"$Jots(dir)\" (selected as your Jots directory), and you don't own it."
	        JotsExit
		return
	    }
	}	
	JotsDirOpen
	return
    }
    TKGDialog jotspop\
	-title "Jots:"\
	-message "Directory \"$Jots(dir)\", needed for Jots, does not exist." \
	-nodismiss \
	-buttons { 
	    { create "Create it" {
		if [catch "exec mkdir $Jots(dir)" text] {
		    error $text
		}
		if [catch "exec chmod 750 $Jots(dir)" err] {
		    error $err
		}
		destroy .jotspop
		JotsDirOpen
	    }			
	    }		    
	    { exit "Exit Jots" {
		destroy .jotspop
		JotsExit
	    }
	    }
	}
}

proc JotsDirOpen {} {    
    global Jots
    cd $Jots(dir)
    if [catch "set filelist \"[exec /bin/ls $Jots(dir)]\"" err] {
	TKGError $err
	return
    }
    set Jots(folderlist) ""
    set Jots(hotlist) ""
    if {"$filelist" != ""} {
	foreach f $filelist {
	    if [Jotsisfolder $f] {
		lappend Jots(folderlist) $f
	    }
	}
    }
    if {$Jots(folderlist) == ""} {
	JotsCreateFolder Notes
	set Jots(folder) Notes
	set Jots(folderlist) [list Notes]
    }
    JotsGetHots
}

proc JotsGetHots {} {
    global Jots
    if ![file exists $Jots(hotfile)] {
	set Jots(hotlist) ""
	if {[lsearch $Jots(folderlist) $Jots(folder)] == -1 } {
	    if {$Jots(folder) == "" } {
		set Jots(folder) [lindex $Jots(folderlist) 0]
	    }
	}
    } else {
	source $Jots(hotfile)
	set sanelist ""
	foreach folder $Jots(hotlist) {
	    if {[lsearch $Jots(folderlist) $folder] != -1} {
		lappend sanelist $folder
	    }
	}
	set Jots(hotlist) $sanelist
	if {[lsearch $Jots(folderlist) $Jots(folder)] == -1 } {
	    if {[set Jots(folder) [lindex $Jots(hotlist) 0]] == ""} {
		set Jots(folder) [lindex $Jots(folderlist) 0]
	    }
	}
    }
    if {[llength $Jots(hotlist)] > 0} { setifunset Jots(showhotlist) 1 }
    .jots.menu.hotlist.m add checkbutton -label "Show hot list" -variable Jots(showhotlist)
    trace variable Jots(showhotlist) w JotsUpdateHots
    JotsFinishInit
}

proc JotsFinishInit {} {
    global Jots
    set JotsGoto ""
    trace variable Jots(Goto) w JotsGotoInvoke 
    trace variable Jots(folder) w JotsGotoUpdate
    JotsPackFind
    set f $Jots(folder)
    set Jots(folder) ""
    JotsGotoFolder $f
    if $Jots(startwithnew) {
	JotsNewEntry
    }
    TKGCenter .jots
}

proc JotsGotoUpdate args {
    global Jots
    set Jots(Goto) $Jots(folder)
}

proc JotsGotoInvoke args {
    global Jots
    if {$Jots(Goto) != $Jots(folder)} {
	JotsGotoFolder $Jots(Goto)
    }
}

proc JotsSaveHots {} {
    global Jots
    if [catch "set id [ open $Jots(hotfile) w ]" err] {
	error $err
	return 0
    }
    puts $id "set Jots(hotlist) \{$Jots(hotlist)\}"
    puts $id "setifunset Jots(folder) $Jots(folder)"
    close $id
    return 1
}    

proc Jotsisfolder {f} {
    if ![file readable $f] {
	TKGError "Error:  $f isn't readable."
	return
    }
    if ![file writable $f] {
	TKGError "Error:  $f isn't writable."
	return
    }
    set id [open $f]
    gets $id s
    close $id
    if {$s != "\#Jots Folder"} {
	return 0
    } else {
	return 1 
    }
}

proc JotsCreateFolder {f} {
    global Jots
    if [file exists $f] {
	TKGError "can't create $f: folder exists"
	return
    }
    if [catch "exec touch $f"] {
	TKGError "can't create $f."
	return
    }
    set id [ open $f w ]
    puts $id "\#Jots Folder"
    puts $id "set JotsList \{\}"
    close $id
    lappend Jots(folderlist) $f
    JotsGotoFolder $f
}

proc JotsOpen {} {
    global Jots
    if ![select f "Open folder:"] {
	return
    }
    if ![file exists $f] {
	TKGDialog jotsopen \
	    -image question\
	    -title Jots: \
	    -message "Folder \"$f\" doesn't exist."\
	    -buttons [subst {
		{ create "Create it" {JotsCreateFolder $f;destroy .jotsopen} }
	    }]
	return
    }
    if ![file readable $f] {
	TKGError "$f isn't readable."
	return
    }
JotsGotoFolder $f
}

proc JotsMerge {} {
    global Jots
    global $Jots(folder)-jf
    JotsUpdateList
    if ![select f "Merge from folder:"] {
	return
    }
    if ![file exists $f] {
	TKGDialog jotsmerge \
	    -image question\
	    -title Jots: \
	    -message "Folder \"$f\" doesn't exist."\
	    -buttons [subst {
		{ create "Create it" {JotsCreateFolder $f;destroy .jotsmerge} }
	    }]
	return
    }
    if ![file readable $f] {
	TKGError "$f isn't readable."
	return
    }
    if {[lsearch $Jots(openfolders) $f] == -1 } {JotsGet $f}
    global $f-jf
    set l [lsort [concat [set $Jots(folder)-jf(list)] [set $f-jf(list)]]]
    set $Jots(folder)-jf(list) ""
    for {set i 0} {$i < [llength $l]} {incr i} {
	lappend $Jots(folder)-jf(list) [lindex $l $i]
	if {[lindex $l $i] == [lindex $l [expr $i + 1]]} {incr i}
    }
    if {[lsearch $Jots(openfolders) $f] == -1 } { unset $f-jf }
    set Jots(index) [expr [llength [set $Jots(folder)-jf(list)]] - 1]
    JotsDisplay
}
    
proc JotsNew {} {
    if ![select f "New folder name:"] {
	return
    }
    JotsCreateFolder $f
}

proc JotsDeleteFolder {} {
    global Jots
    TKGDialog jotsdf \
	-title Jots:\
	-image question\
	-message "Delete folder \"$Jots(folder)\"?"\
	-nodismiss \
	-buttons {
	    { yes Yes {
		if {[set i [lsearch $Jots(hotlist) $Jots(folder)]] != -1} {
		    set Jots(hotlist) [lreplace $Jots(hotlist) $i $i]
		}
		exec /bin/rm $Jots(folder)
		JotsCloseFolder
		destroy .jotsdf
	    } }
	    { no Cancel {
		destroy .jotsdf
	    } }
	}
}

proc JotsClose {} {
    global Jots
    global $Jots(folder)-jf
    JotsUpdateList
    set templist [set $Jots(folder)-jf(list)]
    JotsGet $Jots(folder)
    if {[set $Jots(folder)-jf(list)] != $templist} {
	TKGDialog jotsclose \
	    -title "Jots: folder has changed"\
	    -image question\
	    -message "Save folder \"$Jots(folder)\" before closing?"\
	    -nodismiss \
	    -buttons {
		{ yes Yes {
		    JotsSaveFolder $Jots(folder)
		    JotsCloseFolder
		    destroy .jotsclose
		} }
		{ no No {
		    JotsCloseFolder
		    destroy .jotsclose
		} }
		{ cancel Cancel {
		    destroy .jotsclose
		} }
	    }
    } else { 
	JotsCloseFolder
    }
}

proc JotsCloseFolder {} {
    global Jots
    global $Jots(folder)-jf
    .jots.menu.file.m.openfolders delete $Jots(folder)
    unset $Jots(folder)-jf
    if {[set i [lsearch $Jots(folderlist) $Jots(folder)]] != -1} {
	set Jots(folderlist) [lreplace $Jots(folderlist) $i $i]
    }
    if {[set i [lsearch $Jots(openfolders) $Jots(folder)]] != -1} {
	set Jots(openfolders) [lreplace $Jots(openfolders) $i $i]
    }
    set Jots(folder) ""
    if {[llength $Jots(hotlist)] != 0} {
	JotsGotoFolder [lindex $Jots(hotlist) 0]
    } elseif {[llength $Jots(folderlist)] != 0} {
	JotsGotoFolder [lindex $Jots(folderlist) 0]
    } else { 
	JotsDirOpen
    }
}

proc JotsSave {} {
    global Jots
    JotsSaveFolder $Jots(folder)
}

proc JotsSaveFolder {f} {
    global $f-jf
    set id [ open $f w ]
    puts $id "\#Jots Folder"
    JotsUpdateList
    puts $id "set JotsList \{[set $f-jf(list)]\}"
    close $id
    return 1
}

proc JotsSaveAs {} {
    global Jots
    if ![select f "Folder name:"] {
	return 0
    }
    if [file exists $f] {
	TKGError "can't create $f: folder exists"
	return 0
    }
    if [catch "exec touch $f"] {
	TKGError "can't create $f."
	return 0
    }
    global $f-jf $Jots(folder)-jf
    set $f-jf [set $Jots(folder)-jf]
    JotsSaveFolder $f
    JotsGotoFolder $f
    return 1
}

proc JotsSaveAscii {} {
    global Jots
    global $Jots(folder)-jf
    JotsUpdateList
    cd $Jots(oldcwd)
    set Jots(selectfolders) 0
    if ![select f "Name for Ascii File:"] {
	return 0
    }
    if [file exists $f] {
	TKGError "can't create $f: file exists"
	return 0
    }
    if [catch "exec touch $f"] {
	TKGError "can't create $f."
	return 0
    }
    set id [ open $f w ]
    puts $id "Jots Folder \"$Jots(folder)\" as of [clock format [clock seconds]]\n"
    foreach entry [set $Jots(folder)-jf(list)] {
	puts $id "\n-------\n\nDATE: [lindex $entry 0]  TIME: [lindex $entry 1]"
	puts $id [JotsWrap [lindex $entry 2]]
    }
    close $id
    cd $Jots(dir)
    return 1  
}

proc JotsWrap {text} {
    global Jots
    set linelist [split $text "\n"]
    set outtext ""
    foreach line $linelist {
	set s ""
	set wordlist [split $line]
	foreach word $wordlist {
	    if {$s == ""} {
		set s $word 
	    } elseif {[string length "$s $word"] <= $Jots(columns)} {
		set s "$s $word"
	    } else {
		set outtext "$outtext\n$s"
		set s $word
	    }
	}
	if {$s != ""} { set outtext "$outtext\n$s" }
    }
    return $outtext
}

proc JotsGet {f} {
    global $f-jf Jots
    source $f
    set $f-jf(list) $JotsList
    if {([set $f-jf(list)] != "") && ([llength [lindex [set $f-jf(list)] 0]] == 3) } {
	JotsReformatOldstyleList $f
    }
    set $f-jf(index) [expr [llength [set $f-jf(list)]] - 1]
    set Jots(index) [set $f-jf(index)]
}

proc JotsReformatOldstyleList {f} {
    global $f-jf
    set months [list Zero Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    set weekdays [list Sun Mon Tue Wed Thu Fri Sat]
    set newlist {}
    foreach entry [set $f-jf(list)] {
	set olddate [split [lindex $entry 0] ,]
	set oldtime [split [lindex $entry 1] :]
	set weekday [lsearch $weekdays [string trim [lindex $olddate 0]]]
	set month [format %02d [lsearch $months [string trim [lindex [lindex $olddate 1] 0]]]]
	set date [format %02d [string trim [lindex [lindex $olddate 1] 1]]]
	set year [format %04d [string trim [lindex $olddate 2]]]
	set hour [format %02d [TKGZeroTrim [string trim [lindex $oldtime 0]]]]
	set minute [format %02d [TKGZeroTrim [string trim [lindex $oldtime 1]]]]
	set seconds "00"
	set datelist [list $year $month $date $hour $minute $seconds $weekday]
	lappend newlist [list $datelist [lindex $entry 2]]
    }
    set $f-jf(list) $newlist
}

##########################
# General display, maneuvering, and deleting routines
#

proc JotsScroll {cmd {num ""} {unit ""}} {
    global Jots
    global $Jots(folder)-jf
    switch -- $cmd {
	moveto {
	    if {$num > 1} {set num .999}
	    if {$num < 0} {set num 0}
	    set di [expr int( ([llength [set $Jots(folder)-jf(list)]] * $num)) ]
	    if {$di != $Jots(index)} {
		set Jots(index) $di
		JotsUpdateList
		JotsDisplay
	    }
	} scroll {
	    switch -- $num {
		-1 { 
		    JotsPrev
		} 1 {
		    JotsNext
		}
	    }
	} default {
	    return
	}
    }
}

proc JotsSUpdate args {
    global Jots
    global $Jots(folder)-jf
    if [info exists $Jots(folder)-jf(list)] {
	set w [expr 1/([llength [set $Jots(folder)-jf(list)]] + 0.00001)]
	$Jots(SB) set [expr $w * $Jots(index)]  [expr $w * ($Jots(index) + 1)] 
    }
}

proc JotsUpdateList {} {
    global Jots
    global $Jots(folder)-jf
    set Jots(findmessage) ""
    if {([set $Jots(folder)-jf(list)] != {}) && ($Jots(edited) != -1)} {
	set text [$Jots(textwindow) get 1.0 {end - 1 chars}]
	set $Jots(folder)-jf(list) [lreplace [set $Jots(folder)-jf(list)] $Jots(edited) $Jots(edited) \
			   [list $Jots(datelist) \
				$text ]]
    }
}

proc JotsDisplay args {
    global Jots
    global $Jots(folder)-jf
    set months [list Zero Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    set weekdays [list Sun Mon Tue Wed Thu Fri Sat]
    set Jots(date) ""
    set Jots(time) ""
    set text ""
    $Jots(textwindow) configure -state normal
    $Jots(textwindow) delete 1.0 end
    if { [set $Jots(folder)-jf(list)] != "" } {
 	set entry [lindex [set $Jots(folder)-jf(list)] $Jots(index)]
	set Jots(datelist) [lindex $entry 0]
	set weekday [lindex $weekdays  [TKGZeroTrim [lindex $Jots(datelist) 6]]]
	set month [lindex $months [TKGZeroTrim [lindex $Jots(datelist) 1]]]
	set date [TKGZeroTrim [lindex $Jots(datelist) 2]]
	set year [lindex $Jots(datelist) 0]
	set Jots(date) "$weekday, $month $date, $year"
	set Jots(time) "[lindex $Jots(datelist) 3]:[lindex $Jots(datelist) 4]"
	set text [lindex $entry 1]
	set state normal
    } else { 
	set text "\n\n\n\n\n                           (No entries in folder.)"
	set state disabled
    }
    $Jots(textwindow) insert 1.0 $text
    $Jots(textwindow) configure -state $state
    set Jots(edited) -1
}

proc JotsNewEntry {} {
    global Jots
    global $Jots(folder)-jf
    JotsUpdateList
    set datestr [clock format [clock seconds] -format "%Y %m %d %H %M %S %w"]
    lappend $Jots(folder)-jf(list) [ list $datestr ""]
    set Jots(index) [expr [llength [set $Jots(folder)-jf(list)]] - 1]
    JotsDisplay
    focus $Jots(textwindow)
}

proc JotsCopy {} {
    global Jots
    global $Jots(folder)-jf
    if {[lindex [lindex [set $Jots(folder)-jf(list)] $Jots(index)] 1] == ""} { 
	set Jots(cutbuffer) ""
    } else {
	set Jots(cutbuffer)  [$Jots(textwindow) get 1.0 {end - 1 chars}] 
    }
    selection handle .jots JotsSelectionHandler
    selection own .jots
}

proc JotsCut {} {
    global Jots
    global $Jots(folder)-jf
    JotsUpdateList
    JotsCopy
    if {[set $Jots(folder)-jf(list)] == ""} { return 1 }
    set $Jots(folder)-jf(list) [lreplace [set $Jots(folder)-jf(list)] $Jots(index) $Jots(index)]
    if {[llength [set $Jots(folder)-jf(list)]] == 0} {
	set Jots(index) -1
    } elseif {$Jots(index) == [llength [set $Jots(folder)-jf(list)]]} {
	incr Jots(index) -1
    }
    JotsDisplay
    JotsSUpdate
}

proc JotsPaste {} {
    global Jots
    $Jots(textwindow) insert insert $Jots(cutbuffer)
    set Jots(edited) $Jots(index)
}

proc JotsSelectionHandler {offset maxbytes} {
    global Jots
    return [string range $Jots(cutbuffer) $offset [expr $offset + $maxbytes]]
}

proc JotsPackFind args {
    global Jots
    set w .jots
    switch $Jots(showfindtool) {
	0 {
	    catch "destroy $w.find"
	} 1 {
	    if [winfo exists $w.find] return
	    frame $w.find 
	    button $w.find.find -command JotsFind  -text "Find"
	    pack $w.find.find -side left -expand y -fill y -padx .4c
	    entry $w.find.entry -textvariable Jots(find) -width 30
	    pack $w.find.entry -side left -fill x -padx .3c 
	    bind $w.find.entry <Key-Return> JotsFind
	    label $w.find.label -textvariable Jots(findmessage) -width 15
	    pack $w.find.label -side left -fill x -padx .3c 
	    grid $w.find -row 4 
	    focus $w.find.entry
	}
    }
}

proc JotsFind {} {
    global Jots
    global $Jots(folder)-jf
    JotsUpdateList
    if {$Jots(find) == ""} return
    set l ""
    for {set i 0} {$i < [llength [set $Jots(folder)-jf(list)]]} {incr i} {
	lappend l [lindex [lindex [set $Jots(folder)-jf(list)] $i] 1]
    }
    if {[set i [expr ($Jots(index) + 1 + \
			  [lsearch [lrange $l [expr $Jots(index) + 1] end]\
			       *$Jots(find)*])]] == $Jots(index)} {
	if {[set i [lsearch $l *$Jots(find)* ]] == -1} {
	    set Jots(findmessage) "Not found."
	    return
	}
    }
    set Jots(index) $i
    JotsDisplay
    set Jots(findmessage) "Found."
}

proc JotsPrev {} {
    global Jots
    JotsUpdateList
    if { $Jots(index) == 0 } {return 1}
    incr Jots(index) -1
    JotsDisplay
    focus $Jots(textwindow)
}

proc JotsNext {} {
    global Jots
    global $Jots(folder)-jf
    JotsUpdateList
    if { $Jots(index) == ([llength [set $Jots(folder)-jf(list)]] - 1 )} {return 1}
    incr Jots(index)
    JotsDisplay
    focus $Jots(textwindow)
}

proc JotsDismiss {} {
    global Jots
    JotsUpdateList 
    foreach f $Jots(openfolders) {
	JotsSaveFolder $f
    }
    JotsSaveHots
    JotsFinalExit
}

proc JotsExit {} {
    global Jots
    TKGDialog jots_exit \
	-wmtitle "Jots Exit" \
	-image question\
        -title "Jots: save selected folders before exiting?" \
	-nodismiss \
	-buttons {
	    {
		ok
		OK
		{ 
		    foreach folder $Jots(openfolders) {
			if [set Jots($folder,save)] {JotsSaveFolder $folder}
		    }
		    destroy .jots_exit
		    JotsFinalExit
		}
	    } {
		cancel
		"Cancel"
		{
		    destroy .jots_exit
		}
	    } {
		nosave
		"Exit without\nsaving"
		{
		    destroy .jots_exit
		    JotsFinalExit
		}
	    }
	}


    frame .jots_exit.folders -relief ridge -borderwidth 3
    set  i 0
    foreach folder $Jots(openfolders) {
	set f [string tolower $folder]
	set icalitem$i 0
	checkbutton .jots_exit.folders.$f -text $folder \
		-variable Jots($folder,save)
	set Jots($folder,save) 1
	pack .jots_exit.folders.$f -side top -anchor w -padx 20
    }
    grid .jots_exit.folders -row 1 -sticky ew -padx 3 -pady 3
}

proc JotsFinalExit {} {
    global Jots
    cd $Jots(oldcwd)
    trace vdelete Jots(showfindtool) w JotsPackFind
    trace vdelete Jots(index) w JotsSUpdate
    trace vdelete Jots(showhotlist) w JotsUpdateHots
    trace vdelete Jots(folder) w JotsUpdateHots

    foreach f $Jots(openfolders) {
	global $f-jf
	unset $f-jf
    }
    foreach v { Jots(folder) Jots(textwindow) Jots(oldcwd) Jots(openfolders)
	Jots(hotswindow) Jots(hotlist) Jots(time) Jots(date) Jots(index) 
	Jots(edited) Jots(SB) Jots(selectfolders)
	fileselect selection} {
	global $v
	catch "unset $v"
    }
    if $Jots(makebutton) {
	upvar #0 JotsButton-params P
	catch {$P(pathname) configure -relief $P(relief)}
    }
    destroy .jots
}

#########################
# Folder Management Stuff
#

proc JotsUpdateHots args {
    global Jots
    global $Jots(folder)-jf
    set Jots(findmessage) ""
    pack forget $Jots(hotswindow)
    $Jots(hotswindow) configure
    if !$Jots(showhotlist) {return}
    foreach w [winfo children $Jots(hotswindow)] {destroy $w}
    frame $Jots(hotswindow).pad -height 1 -width 1
    pack $Jots(hotswindow).pad -side left -expand y -fill x
    foreach folder $Jots(hotlist) {
	set w $Jots(hotswindow).[string tolower $folder]
	button $w -text $folder -command "JotsGotoFolder $folder"
	if {$folder == $Jots(folder)} {
	    $w configure -background $Jots(hots_cur_bg) -foreground $Jots(hots_cur_fg)\
		-activebackground $Jots(hots_cur_abg) -activeforeground $Jots(hots_cur_afg)\
		-command {}
	}
	pack $w -side left -expand n
    }
    grid $Jots(hotswindow) -row 1 -column 0 -padx .3c -pady .1c -sticky ew
}

proc JotsGotoFolder {folder} {
    global Jots
    global $Jots(folder)-jf 
    global $folder-jf
    if {$Jots(folder) != ""} {
	JotsUpdateList
	set $Jots(folder)-jf(index) $Jots(index)
    }
    set Jots(folder) $folder
    if {[lsearch $Jots(openfolders) $folder] != -1 } {
	set Jots(index) [set $folder-jf(index)]
    } else {
	JotsGet $Jots(folder)
	lappend Jots(openfolders) $folder
	set m  .jots.menu.file.m.openfolders
	$m add radiobutton -label $folder -variable Jots(Goto) -value $folder
    }
    JotsDisplay
    JotsUpdateHots
    focus $Jots(textwindow)
}

proc JotsAddHot {} {
    global Jots
    if {[lsearch $Jots(hotlist) $Jots(folder)] != -1} return
    lappend Jots(hotlist) $Jots(folder)
    set Jots(hotlist) [lsort $Jots(hotlist)]
    JotsUpdateHots
}

proc JotsRemoveHot {} {
    global Jots
    if {[set i [lsearch $Jots(hotlist) $Jots(folder)]] == -1} return
    set Jots(hotlist) [lreplace $Jots(hotlist) $i $i]
    JotsUpdateHots
}
    

#########################
# Help menu stuff
#

proc JotsAbout {} {

    set text "
Jots, by Mark Crimmins (markcrim@umich.edu), copyright 1995.\n\
Look for the latest version in the tkgoodstuff distribution at:\n\
\ \ \ ftp://merv.philosophy.lsa.umich.edu/pub
"
    set w .about
    catch {destroy $w}
    toplevel $w
    wm title $w "About Jots"
    wm iconname $w "About Jots"

    label $w.title -text "About Jots" 
    pack $w.title -pady .3c -fill x -expand y

    frame $w.view -relief groove -borderwidth 5
    message $w.view.text -width 18c -text $text

    pack $w.view.text -side left -fill both -expand 1
    pack $w.view -side top -fill both -expand 1 -padx .3c

    frame $w.buttons
    button $w.buttons.dismiss -text Dismiss -command "destroy $w"
    pack $w.buttons.dismiss -side left -expand y -fill y -padx .4c -pady .4c
    pack $w.buttons -side bottom -fill x -expand y

}    

proc JotsHelp {} {

    set text "

Jots looks for jots folders in the directory specified in your\
preferences (by default, the directory \".tkgjots\" in the user's home\
directory).  It also looks there for the file \".hotjots\" which\
contains the \"hotlist\" and the last-visited folder name.  The first\
time the user runs Jots, this directory and file (and an intial\
folder called \"Notes\") are created.  

The first folder visited is also specified in the preferences, and\
by default is the folder last visited (according to the .hotjots file), or\
if there is no .hotjots file the alphabetically first folder in the\
directory.

At a given time there is one entry of the current folder on the\
screen.  Scroll through it with the vertical scrollbar, or scroll\
through the entries in the folder with the large, horizontal\
scrollbar.

The hotlist consists of buttons in the upper right of the Jots window\
for visiting folders.  Click a hotlist button to visit the corresponding\
folder, opening it if it is not already open.  By default, the hotlist is\
displayed when Jots is started if the hotlist contains any folders.\
Otherwise, one can display it manually with a command under the\
\"Hotlist\" menu.  When visiting a folder you want in the hotlist,\
other command under the \"Hotlist\" menu will add and delete that\
folder from the hotlist.

Under the \"File\" menu there are commands for creating, opening,\
visiting, merging, saving, and deleting folders, as well as the Exit\
command.  Merging adds the entries of a folder you choose to the\
current folder, which then is re-sorted by date and time, and\
any redundant entries are removed.\

To search for an expression in a folder, use the command under the\
\"Find\" menu to display the Find tool, type in the phrase and press\
the Enter key or the \"Find:\" button.  Searching is case-sensitive,\
and the search\
string may use \"glob\" devices (see the tcl documentation for\
\"string match\" (under \"man -n string\") for more.  There is no\
provision for searching multiple folders at once.

The following keyboard shortcuts are defined:
     <Alt-q> or <Alt-x>	Save and Exit
     <Shift-LeftArrow>	Previous Entry
     <Shift-RightArrow>	Next Entry
     <Shift-Alt-d>		Delete Entry
     <Shift-Alt-n>		New Entry

The rest should be self-explanatory.  See the tkgoodstuff\
documentation for information about customization.

"

    set w .loginscripthelp
    catch {destroy $w}
    toplevel $w
    wm title $w "Jots Help"
    wm iconname $w "Jots Help"

    label $w.title -text "JOTS HELP"
    pack $w.title -pady .3c -fill x -expand y

    frame $w.view
    text $w.view.text -width 65 -height 20 \
	-takefocus 0 -yscrollcommand "$w.view.scrollbar set" \
	-relief sunken -borderwidth 2 -state disabled \
        -wrap word

    pack $w.view.text -side left -fill both -expand 1
    scrollbar $w.view.scrollbar -command "$w.view.text yview"
    pack $w.view.scrollbar -side left -fill y -padx 3
    pack $w.view -side top -fill both -expand 1 -padx .3c
    $w.view.text configure -state normal
    $w.view.text insert end "$text"
    $w.view.text configure -state disabled

    frame $w.buttons
    button $w.buttons.dismiss -text Dismiss -command "destroy $w"
    pack $w.buttons.dismiss -side left -expand y -fill y -padx .4c -pady .4c
    pack $w.buttons -side bottom -fill x -expand y

}    


# File selection stuff

proc select {var {message "Open File"}} {
    global selection
    set selection ""
    fileselect selectdone $message
    tkwait window .fileSelectWindow
    uplevel "set $var \"$selection\"" 
    if { $selection == "" } {
	return 0
    } else {
	return 1
    }
}

proc selectdone {f} {
    global selection 
    set selection $f
}

#
# fileselect.tcl --
# simple file selector.
#
# Mario Jorge Silva			          msilva@cs.Berkeley.EDU
# University of California Berkeley                 Ph:    +1(510)642-8248
# Computer Science Division, 571 Evans Hall         Fax:   +1(510)642-5775
# Berkeley CA 94720                                 
# 
# Layout:
#
#  file:                  +----+
#  ____________________   | OK |
#                         +----+
#
#  +------------------+    Cancel
#  | ..               |S
#  | file1            |c
#  | file2            |r
#  |                  |b
#  | filen            |a
#  |                  |r
#  +------------------+
#  currrent-directory
#
# Copyright 1993 Regents of the University of California
# Permission to use, copy, modify, and distribute this
# software and its documentation for any purpose and without
# fee is hereby granted, provided that this copyright
# notice appears in all copies.  The University of California
# makes no representations about the suitability of this
# software for any purpose.  It is provided "as is" without
# express or implied warranty.
#


# names starting with "fileselect" are reserved by this module
# no other names used.

# use the "option" command for further configuration



# this is the default proc  called when "OK" is pressed
# to indicate yours, give it as the first arg to "fileselect"

proc fileselect.default.cmd {f} {
  puts stderr "selected file $f"
}


# this is the default proc called when error is detected
# indicate your own pro as an argument to fileselect

proc fileselect.default.errorHandler {errorMessage} {
    puts stdout "error: $errorMessage"
    catch { cd ~ }
}

# this is the proc that creates the file selector box

proc fileselect {
    {cmd fileselect.default.cmd} 
    {purpose "Open file:"} 
    {w .fileSelectWindow} 
    {errorHandler fileselect.default.errorHandler}} {

    catch {destroy $w}

    toplevel $w
    wm withdraw $w
    grab $w
    wm title $w "Select File"


    # path independent names for the widgets
    global fileselect

    set fileselect(entry) $w.file.eframe.entry
    set fileselect(list) $w.file.sframe.list
    set fileselect(scroll) $w.file.sframe.scroll
    set fileselect(ok) $w.bframe.okframe.ok
    set fileselect(cancel) $w.bframe.cancel
    set fileselect(dirlabel) $w.file.dir.dirlabel

    # widgets
    frame $w.file -bd 10 
    frame $w.bframe -bd 10
    pack append $w \
        $w.file {left filly} \
        $w.bframe {left expand frame n}

    frame $w.file.eframe
    frame $w.file.sframe
    frame $w.file.dir
    label $w.file.dir.dir  -anchor e -width 6 -text "Dir:"
    label $w.file.dir.dirlabel -anchor e -width 24 -text [pwd] 
    pack $w.file.dir.dir $w.file.dir.dirlabel -side left

    pack append $w.file \
        $w.file.eframe {top frame w} \
	$w.file.sframe {top fillx} \
	$w.file.dir {top frame w}


    label $w.file.eframe.label -anchor w -width 24 -text $purpose
    entry $w.file.eframe.entry -relief sunken 

    pack append $w.file.eframe \
		$w.file.eframe.label {top expand frame w} \
                $w.file.eframe.entry {top fillx frame w} 


    scrollbar $w.file.sframe.yscroll -relief sunken \
	 -command "$w.file.sframe.list yview"
    listbox $w.file.sframe.list -relief sunken \
	-yscroll "$w.file.sframe.yscroll set" 

    pack append $w.file.sframe \
        $w.file.sframe.yscroll {right filly} \
 	$w.file.sframe.list {left expand fill} 

    # buttons
    frame $w.bframe.okframe -borderwidth 2 -relief sunken
 
    button $w.bframe.okframe.ok -text OK -relief raised -padx .3c \
        -command "fileselect.ok.cmd $w $cmd $errorHandler"

    button $w.bframe.cancel -text cancel -relief raised -padx .3c \
        -command "fileselect.cancel.cmd $w"
    pack append $w.bframe.okframe $w.bframe.okframe.ok {padx .3c pady .3c}

    pack append $w.bframe $w.bframe.okframe {expand padx 20 pady 20}\
                          $w.bframe.cancel {top}

    # Fill the listbox with a list of the files in the directory (run
    # the "/bin/ls" command to get that information).
    # to not display the "." files, remove the -a option and fileselect
    # will still work
 
    global Jots
    if $Jots(selectfolders) {
	foreach i [exec /bin/ls [pwd]] {
	    if {[string compare $i "."] != 0 && \
		    [string compare $i ".."] != 0 } {
		$fileselect(list) insert end $i
	    }
	}
    } else {
	$fileselect(list) insert end ".."
	foreach i [exec /bin/ls -a [pwd]] {
	    if {[string compare $i "."] != 0 && \
		    [string compare $i ".."] != 0 } {
		$fileselect(list) insert end $i
	    }
	}
    }

   # Set up bindings for the browser.
    bind $fileselect(entry) <Return> {eval $fileselect(ok) invoke; break}
    bind $fileselect(entry) <Control-c> {eval $fileselect(cancel) invoke; break}

    bind $w <Control-c> {eval $fileselect(cancel) invoke;break}
    bind $w <Return> {eval $fileselect(ok) invoke;break}


#    tk_listboxSingleSelect $fileselect(list)


    bind $fileselect(list) <Button-1> {
        # puts stderr "button 1 release"
        %W selection set [%W nearest %y]
	$fileselect(entry) delete 0 end
	$fileselect(entry) insert 0 [%W get [%W nearest %y]]
	break
    }

    bind $fileselect(list) <Key> {
        %W selection set [%W nearest %y]
        $fileselect(entry) delete 0 end
	$fileselect(entry) insert 0 [%W get [%W nearest %y]]
	break
    }

    bind $fileselect(list) <Double-ButtonPress-1> {
        # puts stderr "double button 1"
        %W selection set [%W nearest %y]
	$fileselect(entry) delete 0 end
	$fileselect(entry) insert 0 [%W get [%W nearest %y]]
	$fileselect(ok) invoke
	break
    }

    bind $fileselect(list) <Return> {
        %W selection set [%W nearest %y]
	$fileselect(entry) delete 0 end
	$fileselect(entry) insert 0 [%W get [%W nearest %y]]
	$fileselect(ok) invoke
	break
    }

    # set kbd focus to entry widget

    focus $fileselect(entry)

    #center window
    TKGCenter $w
}


# auxiliary button procedures

proc fileselect.cancel.cmd {w} {
    # puts stderr "Cancel"
    destroy $w
}

proc fileselect.ok.cmd {w cmd errorHandler} {
    global fileselect Jots
    set selected [$fileselect(entry) get]

    # some nasty file names may cause "file isdirectory" to return an error
    set sts [catch { 
	file isdirectory $selected
    }  errorMessage ]

    if { $sts != 0 } then {
	$errorHandler $errorMessage
	destroy $w
	return

    }

    # clean the text entry and prepare the list
    $fileselect(entry) delete 0 end
    $fileselect(list) delete 0 end
    if !$Jots(selectfolders) {$fileselect(list) insert end ".."}

    # selection may be a directory. Expand it.

    if {[file isdirectory $selected] != 0} {
	if !$Jots(selectfolders) {
	    cd $selected
	    set dir [pwd]
	    $fileselect(dirlabel) configure -text $dir
	    foreach i [exec /bin/ls -a $dir] {
		if {[string compare $i "."] != 0 && \
			[string compare $i ".."] != 0} {
		    $fileselect(list) insert end $i
		}
	    }
	}
	return
    }

    destroy $w
    $cmd $selected
}
##### end of fileselect code


DEBUG "Loaded Jots.tcl"
