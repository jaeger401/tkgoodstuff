#Fvwm module interface for tkgoodstuff

proc FvwmDeclare {} {
    TKGDeclare Fvwm(dostyle) 1 -vartype boolean \
	-typelist [list General Fvwm]\
	-label "Tell Fvwm to make tkgoodstuff stay on top, etc."\
	-help {You can configure Fvwm to treat tkgoodstuff specially
by not giving it a title, borders, by letting it stay
on top, not including it in the window list or circulation
list, and so on.  By default, when launched by fvwm, tkgoodstuff
tells fvwm to do all of this automatically.}
}

proc FvwmDoOnLoad {} {
    if [info exists Fvwm(outid)] return
    #ensure tkfvwm is loaded
    package require Tkfvwm
    # Set up communication with fvwm
    if [catch "fvwm init [lindex $argv 0] [lindex $argv 1]" e] {
	TKGError "Something went wrong trying to initialize communication with fvwm:
$e" exit
    }
    set Fvwm(outid) [lindex $argv 0]
    if $Fvwm(dostyle) {
	setifunset Fvwm(Style) {
	    "BorderWidth 0"
	    CirculateSkipIcon
	    CirculateSkip
	    ClickToFocus
	    NoTitle
	    NoHandles
	    Sticky
	    WindowListSkip
	    StaysOnTop
	    RandomPlacement
	}
	fvwm send $Fvwm(outid) "Style \"tkgoodstuff\" [join $Fvwm(Style) ,]"
	unset Fvwm(Style)
    }
    bind TkgButton <1> "FvwmTkgbuttonStuff %W; [bind TkgButton <1>]"
    TKGAddToHook TKG_alldone_hook FvwmTKGButtonInit
    FvwmStart
}

# Set up bindings for fvwm messages, and ask fvwm for all window data
proc FvwmStart {} {
    global Fvwm
    fvwm AddWindow {FvwmAddWindow %W %f %x %y %w %h %t}
    fvwm ConfigureWindow {FvwmConfigureWindow %W %f %x %y %w %h %t}
    fvwm DestroyWindow {FvwmDestroyWindow %W}
    fvwm WindowName {FvwmWindowName %W %N}
    fvwm IconName {FvwmIconName %W %N}
    fvwm ResName {FvwmResName %W %N}
    fvwm ResClass {FvwmResClass %W %N}
    fvwm NewPage {FvwmNewPage %X %Y %D %x %y}
    fvwm NewDesk {FvwmNewDesk %T}
    fvwm Map {FvwmMap %W}
    fvwm Iconify {FvwmIconify %W %x %y %w %h}
    fvwm IconLocation {FvwmIconLocation %W %x %y %w %h}
    fvwm Deiconify {FvwmDeiconify %W}
    fvwm FocusChange {FvwmFocusChange %W}
 #    fvwm IconFile {FvwmIconFile %W %N}
 #    fvwm DefaultIcon {FvwmDefaultIcon %W %N}
 #    fvwm String {FvwmString %N}
 #    fvwm MiniIcon {FvwmMiniIcon %W %N}
    TKGDoHook FvwmStartHook
    fvwm send $Fvwm(outid) Send_WindowList
}

# Cancel fvwm message binding while tkgoodstuff is redrawing
proc FvwmSuspend {} {
    foreach c {
	AddWindow ConfigureWindow DestroyWindow WindowName IconName
	ResName ResClass NewPage NewDesk Map Iconify IconLocation
	Deiconify FocusChange} {
	fvwm $c {}
	# Iconfile DefaultIcon String MiniIcon
    }
}

proc FvwmCreateWindow {} {}

# Other clients (e.g., WWW) might call this
proc TKGExec {cmd {name ""}} {
    FvwmNextOrExec $cmd $name
}

# A click on a sunken button takes us to next
# window of the appropriate name.
proc FvwmTkgbuttonStuff {w} {
    if [string match [$w cget -relief] sunken] {
	if ![Empty [set wn [$w cget -windowname]]] {
	    FvwmNext $wn
	}
    }
}

# Restarting an fvwm module requires telling fvwm to invoke it.
proc TKGRestart {} {
    global Fvwm argv argv0
    fvwm send $Fvwm(outid) \
	"[file tail $argv0] [lreplace $argv 0 4]"
    after 500
    TKGQuit
}

# If we just exit, an fvwm bug can make fvwm race if we're leaving
# children (as of fvwm2-0-43).
proc TKGReallyQuit {} {
    fvwm send 0 KillMe
    exit
}

proc FvwmNextOrExec {cmd {name ""}} {
    global Fvwm
    if ![FvwmNext [list $name]] {
	if [catch "exec $cmd &" err] {
	    TKGError $err
	}
    }
}

# We locate the next window in our list whose WindowName or ResClass 
# matches one of the names, and goto it.
proc FvwmNext {{names ""} {incr 1}} {
    global Fvwm FvwmWL FvwmW
    if [info exists Fvwm(NextLast)] {
	set current $Fvwm(NextLast)
    } else {
	set current $FvwmW(focus)
    }
    set wl [lsort [array names FvwmWL]]
    set i [expr ([lsearch $wl $current] + $incr) % [llength $wl]]
    set wl [concat [lrange $wl $i end] $wl]
    foreach w $wl {
	foreach name $names {
	    set name [string tolower [set name]*]
	    foreach vartype {windowname resname resclass} {
		if [string match $name \
			[string tolower $FvwmW($w,$vartype)]] {
		    set answer 1
		    break
		}
	    }
	    if [info exists answer] break
	}
	if [info exists answer] break
    }
    if ![info exists answer] {
	return 0
    }
    FvwmGoto $w
    return 1
}

# We go to the right desk and page, and raise.  If the window has a
# style flag set for ClickToFocus (2^10) or SloppyFocus (2^11) we give 
# it focus (with MouseFocus focusing warps the pointer).
proc FvwmGoto {w} {
    global Fvwm FvwmW
    fvwm send $w {Iconify -1}
    fvwm send $w {Raise ""}
    fvwm send $Fvwm(outid) "Desk 0 $FvwmW($w,t)"
    fvwm send $Fvwm(outid) "GotoPage $FvwmW($w,npagex) $FvwmW($w,npagey)"
    if {$FvwmW($w,flags) & 3072} {
	fvwm send $w "Focus"
    }
    set Fvwm(NextLast) $w
}

proc FvwmPrev {{name ""}} {FvwmNext $name -1}

# Code to maintain our own window database

proc FvwmAddWindow {id flags x y w h t} {
    FvwmConfigureWindow $id $flags $x $y $w $h $t
    TKGDoHook Fvwm_AddWindow_hook $id
}

proc FvwmConfigureWindow {id flags x y w h t} {
    global FvwmW FvwmWL
    if ![info exists FvwmW($id,iconic)] {set FvwmW($id,iconic) 0}
    foreach var {flags x y w h t} {
	set FvwmW($id,$var) [set $var]
    }
    set FvwmW($id,npagex) [expr ($x+$FvwmW(pagex))/[winfo vrootwidth .]]
    if {$FvwmW($id,npagex)<0} {set FvwmW($id,npagex) 0}
    set FvwmW($id,npagey) [expr ($y+$FvwmW(pagey))/[winfo vrootheight .]]
    if {$FvwmW($id,npagey)<0} {set FvwmW($id,npagey) 0}
    set FvwmWL($id) 0
    TKGDoHook Fvwm_ConfigureWindow_hook $id
}

proc FvwmWindowName {id name} {
    global FvwmW
    set FvwmW($id,windowname) $name
    # sometimes apparently resclass and resname don't get set
 #    if ![info exists FvwmW($id,resclass)] {
 #	set FvwmW($id,resclass) dummyclass
 #	set FvwmW($id,resname) dummyname
 #    }
    FvwmTKGButtonCheck $name
    TKGDoHook Fvwm_WindowName_hook $id
}

proc FvwmIconName {id name} {
    global FvwmW
    set FvwmW($id,iconname) $name
    TKGDoHook Fvwm_IconName_hook $id
}

proc FvwmResName {id name} {
    global FvwmW
    set FvwmW($id,resname) $name
    TKGDoHook Fvwm_ResName_hook $id
}

proc FvwmResClass {id name} {
    global FvwmW
    set FvwmW($id,resclass) $name
    FvwmTKGButtonCheck $name
    TKGDoHook Fvwm_ResClass_hook $id
}

proc FvwmDestroyWindow {id} {
    global FvwmWL FvwmW
    catch {unset FvwmWL($id)}
    FvwmTKGButtonCheck $FvwmW($id,windowname)
    FvwmTKGButtonCheck $FvwmW($id,resclass)
    TKGDoHook Fvwm_DestroyWindow_hook $id
    foreach index [array names FvwmW] {
	if [string match $id, $index] {
	    unset FvwmW($index)
	}
    }
}

# For sticky windows, we get no configure message, so we recalc page
# on NewPage.
proc FvwmNewPage {X Y D x y} {
    global Fvwm FvwmW FvwmWL
    set FvwmW(pagex) $X
    set FvwmW(pagey) $Y
    set FvwmW(npagex) [expr $FvwmW(pagex)/[winfo vrootwidth .]]
    set FvwmW(npagey) [expr $FvwmW(pagey)/[winfo vrootheight .]]
    set FvwmW(desktop) $D
    set FvwmW(maxpagex) $x
    set FvwmW(maxpagey) $y

    foreach id [array names FvwmWL] {
	if {$FvwmW($id,flags) & 4} {
	    set FvwmW($id,npagex) [expr ($FvwmW($id,x)+$X)/[winfo vrootwidth .]] 
	    if {$FvwmW($id,npagex)<0} {set FvwmW($id,npagex) 0}
	    set FvwmW($id,npagey) [expr ($FvwmW($id,y)+$Y)/[winfo vrootheight .]]
	    if {$FvwmW($id,npagey)<0} {set FvwmW($id,npagey) 0}
	    set FvwmW($id,t) $D
	    TKGDoHook Fvwm_ConfigureWindow_hook $id
	}
    }
    TKGDoHook Fvwm_NewPage_hook
}

proc FvwmNewDesk {T} {
    global FvwmW
    set FvwmW(desktop) $T
    TKGDoHook Fvwm_NewDesk_hook
}

proc FvwmIconify {id x y w h} {
    global FvwmW
    set FvwmW($id,iconic) 1
    set FvwmW($id,iconlocx) $x
    set FvwmW($id,iconlocy) $y
    set FvwmW($id,iconw) $w
    set FvwmW($id,iconh) $h
    TKGDoHook Fvwm_Iconify_hook $id
}

proc FvwmIconLocation {id x y w h} {
    global FvwmW
    set FvwmW($id,iconx) $x
    set FvwmW($id,icony) $y
    set FvwmW($id,iconw) $w
    set FvwmW($id,iconh) $h
    TKGDoHook Fvwm_IconLocation_hook $id
}

proc FvwmDeiconify {id} {
    global FvwmW
    set FvwmW($id,iconic) 0
    TKGDoHook Fvwm_Deiconify_hook $id
}

proc FvwmFocusChange {id} {
    global FvwmW
    set FvwmW(focus) $id
    TKGDoHook Fvwm_FocusChange_hook $id
}

proc FvwmMap {id} {
    global FvwmW
    set FvwmW($id,mapped) 1
    TKGDoHook Fvwm_Map_hook $id
}

proc FvwmIconFile {id file} {
    global FvwmW
    set FvwmW($id,iconfile) $file
    TKGDoHook Fvwm_IconFile_hook $id
}

proc FvwmMiniIcon {id file} {
REPORT id file
    global FvwmW
    set FvwmW($id,miniicon) $file
    TKGDoHook Fvwm_MiniIcon_hook $id
}

proc FvwmDefaultIcon {id icon} {
    global FvwmW
    set FvwmW($id,defaulticon) $icon
    TKGDoHook Fvwm_DefaultIcon_hook $id
}

# Fvwm can now send modules an arbitrary string
proc FvwmString {s} {
    TKGDoHook Fvwm_String_hook $s
}

# Utilities used by TKGButtons

# Check if any windows with windowname or resclass matching pattern
proc FvwmAnyWindowsOfName {pattern} {
    global FvwmWL FvwmW
    set somewins 0
    foreach id [array names FvwmWL] {
	if {[string match $pattern $FvwmW($id,windowname)]
	    || [string match $pattern $FvwmW($id,resclass)]} {
	    set somewins 1
	    break
	}
    }
    return $somewins
}

# Check if any TKGButton is looking for a window with
#  windowname or resclass of name.
proc FvwmTKGButtonCheck {name} {
    global FvwmWL FvwmW Fvwm_trackbuttons
    foreach pattern [array names Fvwm_trackbuttons] {
	if [string match $pattern $name] {
	    FvwmTKGButtonTrack $pattern
	}
    }
}

# Set relief of all TKGButtons tracking pattern
proc FvwmTKGButtonTrack {pattern} {
    global Fvwm_trackbuttons TKG
    if [FvwmAnyWindowsOfName $pattern] {
	set relief sunken
    } else {
	set relief notsunken
    }
    foreach buttonname $Fvwm_trackbuttons($pattern) {
	upvar \#0 $buttonname-params P
	if [winfo exists $P(pathname)] {
	    if {[string match notsunken $relief]} {
		set relief $P(relief)
		if {[Empty $relief]} {
		    set relief $TKG(butrelief)
		}
	    }
	    $P(pathname) configure -relief $relief
	}
    }
}

# Set relief of all TKGButtons
proc FvwmTKGButtonInit {} {
    foreach pattern [array names Fvwm_trackbuttons] {
	FvwmTKGButtonTrack $pattern
    }
}	

DEBUG "We're an fvwm module.  Loaded Fvwm.tcl"
