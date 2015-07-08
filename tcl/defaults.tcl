proc TKGDeclare {var default args} {
    global $var TKGVars TKGVarnames TKGTypes
    set TKGVarnames($var) 1
    for {set i 0} {$i < [llength $args]} {incr i} {
	if [regexp -- -(.*) [lindex $args $i] switch switch] {
	    set TKGVars($var,$switch) [lindex $args [incr i]]
	}
    }
    set TKGVars($var,default) $default
    if ![info exists TKGVars($var,current)] {
	if {[Empty $TKGVars($var,default)] \
		&& [info exists TKGVars($var,fallback)]} {
	    TKGSet $var ""
	    uplevel \#0 set $var $TKGVars($var,fallback)
	} {
	     TKGSet $var $TKGVars($var,default)
	}
    }
    if ![info exists TKGVars($var,typelist)] {
	set TKGVars($var,typelist) {}
    }
    lappend TKGTypes([join $TKGVars($var,typelist) ,]) $var
    if ![info exists TKGVars($var,vartype)] {
	set TKGVars($var,vartype) entry
    }
    if ![info exists TKGVars($var,label)] {
	set TKGVars($var,label) $var
    }
    if ![info exists TKGVars($var,help)] {
	set TKGVars($var,help) ""
    }
}

proc TKGColorDeclare {var default typelist {label {}} {fallback $TKG(panelcolor)}} {
    if [Empty $label] {set label $var}
    TKGDeclare $var $default \
	-typelist $typelist -label $label -vartype color -fallback $fallback
}

proc TKGSet {var val} {
    global TKGVars $var
    set TKGVars($var,current) $val
    if [catch {set upval [uplevel \#0 [list subst $val]]} err] {
	# maybe we're referencing a variable that's not defined yet
	TKGAddToHook TKGSetHook [list TKGSet $var $val]
    } else {
	uplevel \#0 [list set $var $upval]
    }
}

set Prefs_taborder(:) "Configuration General Geometry Buttons"
set Prefs_taborder(:General) "Misc Colors Fonts Directories Debugging Fvwm"
set Prefs_taborder(:General,Fonts) "Main ResourceFonts"


set Prefs_typecomment(:Configuration) \
    "NOTE: tkgoodstuff must be restarted for (saved) preference changes to take effect."
set Prefs_typelabel(Geometry) "Screen Geometry"
TKGDeclare TKG(screenedge) no \
    -typelist Geometry\
    -label "Screen-Edge Mode" \
    -help "Span a side of the screen?"\
    -vartype optionMenu \
    -optionlist {no left right top bottom}
TKGDeclare TKG(automin) 0 \
    -typelist Geometry\
    -label "Auto-minimize" \
    -help "If screen-edge mode is not \"no\", when the cursor leaves tkgoodstuff,\
tkgoodstuff becomes a line on the screen edge (enter that line to resume)."\
    -vartype boolean
TKGColorDeclare TKG(minbg) \#7fff00\
    Geometry "Minimized color (for screenedge bar)"
TKGDeclare TKG(geometry) -0+0\
    -typelist Geometry\
    -label "Main Panel Position\n(if not in screen-edge mode)"\
    -help "Takes an XY screen position specification like -2+200, where \"+\" means\
from the left or top, and \"-\" means from the right or bottom."
TKGDeclare TKG(orientation) vertical\
    -typelist Geometry\
    -label "Orientation"\
    -help "Main panel orientation (if not in screen-edge mode)."\
    -vartype optionMenu\
    -optionlist {horizontal vertical}
TKGDeclare TKG(icons) {$TKG(libdir)/icons:/usr/include/X11/pixmaps}\
    -typelist [list General Directories]\
    -scrollbar 1\
    -label "Directories for Icon files"\
    -help "Takes a colon-separated list of directory names."
TKGDeclare TKG(tmpdir) /tmp\
    -typelist [list General Directories]\
    -label "Directory for temporary files"
TKGDeclare TKG(xtraauto) ""\
    -typelist [list General Directories]\
    -label "Additional tcl code directories"\
    -help "The directories in this space-separated list are prepended
to auto_path, which means that tcl procedures listed in the
tclIndex files in these directories can be used in user-defined
buttons and menu items, and that you can replace tkgoodstuff
procedures with your own."

set Prefs_typelabel(General) "General Options"
TKGDeclare TKG(iconscale) ""\
    -typelist [list General Misc]\
    -vartype radio -radioside left\
    -label {Size of icons}\
    -radiolist {{Small "-sm"} {Large ""}}
TKGDeclare TKG(labelsonly) 0\
    -typelist {Buttons}\
    -vartype boolean\
    -label {Omit icons on buttons}
TKGDeclare TKG(iconsonly) 0\
    -typelist {Buttons}\
    -vartype boolean\
    -label {Omit text on buttons}
TKGDeclare TKG(iconside) ""\
    -typelist {Buttons}\
    -vartype optionMenu\
    -label {On which side is the icon?}\
    -help {Leave unset to use the default, which depends on various factors.}\
    -optionlist {left right top bottom}
TKGDeclare TKG(butrelief) "flat"\
    -typelist {Buttons}\
    -vartype optionMenu\
    -label {Normal relief for buttons.}\
    -optionlist {flat raised}
TKGDeclare TKG(paneltile) "" \
    -typelist [list General Misc] \
    -label {Image (file) to tile in background of panel.}
TKGDeclare TKG(buttontile) "" \
    -typelist [list Buttons] \
    -label {Image (file) to tile in background of buttons.}
TKGDeclare TKG(balloons) 1\
    -typelist [list General Misc] -vartype boolean\
    -label {Produce help "balloons"}
TKGDeclare TKG(borderwidth) 2\
    -typelist [list General Misc]\
    -label {Width (in pixels) of the panel border}
TKGDeclare TKG(padding) 2\
    -typelist {Buttons}\
    -label {Padding (in pixels) surrounding image and/or text.}
TKGDeclare TKG(butsep) 2\
    -typelist {Buttons}\
    -label {Padding (in pixels) between image and text.}
TKGDeclare tk_strictMotif 1\
    -typelist {Buttons} -vartype boolean\
    -label {"Strict Motif" buttons.}\
    -help "Strict Motif buttons do not wiggle when you press them, nor
do they change color when you pass over them.
They are also two pixels smaller in each dimension."
TKGDeclare TKG(sep) 2\
    -typelist {Buttons}\
    -label {Padding (in pixels) between buttons.}
TKGDeclare TKG(butborder) 1\
    -typelist {Buttons}\
    -label {Degree of relief (in pixels) on buttons.}
TKGDeclare TKG(nobeep) 0\
    -typelist [list General Misc]\
    -vartype boolean\
    -label {Don't Ever Beep}
set TKG(nonotices) 0
TKGDeclare TKG(browser) netscape\
    -typelist [list General Misc]\
    -label {Default web browser for various purposes}
TKGDeclare TKG(webpage) "http://www-personal.umich.edu/~markcrim/tkgoodstuff"\
    -typelist [list General Misc]\
    -label {tkgoodstuff Home Page}
TKGDeclare TKG(internallogging) 0\
    -vartype boolean\
    -typelist {General Debugging}\
    -label "Keep an internal log"
TKGDeclare TKG(filelogging) 0\
    -vartype boolean\
    -typelist {General Debugging}\
    -label "Log to a file"
TKGDeclare TKG(logfile) {$TKG(tmpdir)/tkglog}\
    -typelist {General Debugging}\
    -label "Log to what file?"
TKGDeclare TKG(dialogtextwidth) 80 -typelist [list General Misc]\
    -label "Width in characters of text windows in dialogs."
TKGDeclare TKG(dialogtextheight) 20 -typelist [list General Misc]\
    -label "Height in rows of text windows in dialogs."

TKGSet TKG(config) \
{Client Clock
Client WWW
Client Biff
PanelButton Utilities
Client Menu
Panel Utilities
Client Webster
Client Jots
Client Calc
EndPanel
}

TKGDeclare TKG(config) $TKG(config) -typelist "Configuration"\
    -nodefault 1\
    -nolabel 1\
    -vartype config\
    -help {Here you list what you want in your tkgoodstuff panel.

Click mouse button 3 over any item for a menu of commands, including
a command to insert a new item.

Mouse button 1 can be used to select an item, and then to move it
from one place to another.  Double-clicking on an item selects a
"property sheet" for configuring the item.
    }

proc TKGDefaults {} {uplevel {
    if {![Empty $TKG(paneltile)]} {
	SetImage paneltileimage $TKG(paneltile)
	set TKG(paneltileimage) paneltileimage
    } else {
	set TKG(paneltileimage) ""
    }
    if {![Empty $TKG(buttontile)]} {
	SetImage buttontileimage $TKG(buttontile)
	set TKG(buttontileimage) buttontileimage
    } else {
	set TKG(buttontileimage) ""
    }
    TKGColorDeclare TKG(panelcolor) \#b0b0b0 \
	 [list General Colors] \
	 "Background color of panel"
    TKGColorDeclare TKG(background) #b0b0b0\
	 [list General Colors]\
	 "Basic background color."
    TKGColorDeclare TKG(foreground) \#000000\
	 [list General Colors]\
	 "Basic foreground color (for typefaces, etc.)"
    set TKG(buttonbackground) $TKG(panelcolor)
    set TKG(buttonforeground) $TKG(foreground)
    set bg [winfo rgb . $TKG(background)]       
    #this stolen from palette.tcl in tk4.0
    foreach i {0 1 2} {
	set light($i) [expr [lindex $bg $i]/256]
	set inc1 [expr ($light($i)*15)/100]
	set inc2 [expr (255-$light($i))/3]
	if {$inc1 > $inc2} {
	    incr light($i) $inc1
	} else {
	    incr light($i) $inc2
	}
	if {$light($i) > 255} {
	    set light($i) 255
	}
    }
    set TKG(activebackground) \
	[format #%02x%02x%02x $light(0) $light(1) $light(2)]
    set TKG(activeforeground) $TKG(buttonforeground)
    set bg [winfo rgb . $TKG(panelcolor)]       
    foreach i {0 1 2} {
	set light($i) [expr [lindex $bg $i]/256]
	set inc1 [expr ($light($i)*15)/100]
	set inc2 [expr (255-$light($i))/3]
	if {$inc1 > $inc2} {
	    incr light($i) $inc1
	} else {
	    incr light($i) $inc2
	}
	if {$light($i) > 255} {
	    set light($i) 255
	}
    }
    set TKG(butactivebackground) \
	     [format #%02x%02x%02x $light(0) $light(1) $light(2)]
    set TKG(butactiveforeground) $TKG(buttonforeground)
    set TKG(highlightcolor) $TKG(activeforeground)
    set TKG(labelboxbackground) [tkDarken $TKG(panelcolor) 115]
    set TKG(textbackground) [tkDarken $TKG(background) 115]
    set TKG(textforeground) $TKG(foreground)
    set TKG(labelboxforeground) $TKG(foreground)
    set TKG(disabledforeground) [tkDarken $TKG(buttonbackground) 50]
    set TKG(menutitleforeground) #ce0000
    set TKG(noticetitleforeground) #ce0000
    set TKG(scrollbartrough) [tkDarken $TKG(background) 115]
    set TKG(entrybackground) $TKG(textbackground)
    set TKG(balloonbackground) #ffcf30

    TKGDeclare TKG(fontscale) 1\
        -typelist [list General Fonts Main]\
        -vartype radio -radioside left\
        -label {Size of fonts}\
        -radiolist {{Small 0} {Medium 1} {Large 2}}
    TKGDeclare TKG(fontfamily) "helvetica" -vartype optionMenu \
        -typelist [list General Fonts Misc]\
	-optionlist [font families] -label "Default font family"

 # As of 8.0a2 this could blow up
 #	      foreach family [font families] {
 #		  if [string match utopia $family] continue
 #		  if {(![catch {
 #		      set fixed [font metrics [list $family 12] -fixed]
 #		  }]) && $fixed} {
 #		      lappend fixedfamilies $family
 #		  }
 #	      }

    TKGDeclare TKG(fixedfontfamily) "clean" -vartype optionMenu \
        -typelist [list General Fonts Misc]\
        -optionlist [font families] -label "Default fixed-width font family"
	      
#	      unset fixedfamilies

    set sizes {6 8 10 12 14 18 24}
    TKGDeclare TKG(fontsmallsize) \
	[lindex $sizes [expr $TKG(fontscale)]] \
        -typelist [list General Fonts Misc]\
        -vartype optionMenu \
	-optionlist $sizes -label "Default small font size"
    TKGDeclare TKG(fontmediumsize) \
	[lindex $sizes [expr 1 + $TKG(fontscale)]] \
        -typelist [list General Fonts Misc]\
        -vartype optionMenu \
	-optionlist $sizes -label "Default medium font size"
    TKGDeclare TKG(fontbigsize) \
	[lindex $sizes [expr 2 + $TKG(fontscale)]] \
        -typelist [list General Fonts Misc]\
        -vartype optionMenu \
	-optionlist $sizes -label "Default big font size"
    TKGDeclare TKG(fonthugesize) \
	[lindex $sizes [expr 3 + $TKG(fontscale)]] \
        -typelist [list General Fonts Misc]\
        -vartype optionMenu \
	-optionlist $sizes -label "Default huge font size"
    TKGDeclare TKG(fontHugesize) \
	[lindex $sizes [expr 4 + $TKG(fontscale)]] \
        -typelist [list General Fonts Misc]\
        -vartype optionMenu \
	-optionlist $sizes -label "Default HUGE font size"
    unset sizes

    TKGDeclare TKG(generalfont) {} -fallback {tkgbig}\
         -vartype font\
         -typelist [list General Fonts Main]\
	 -label "Main All-Purpose Font"\
	 -help "Defaults to default big font."
    TKGDeclare TKG(combofont) {} -fallback {tkgmedium}\
         -vartype font\
	-typelist [list General Fonts Main]\
		  -label "Font on Buttons with Icons"\
		  -help "Defaults to default medium font."
    TKGDeclare TKG(labelonlyfont) {} -fallback {tkgbig}\
         -vartype font\
	-typelist [list General Fonts Main]\
	 -label "Font on Buttons without Icons"\
	 -help "Defaults to default big font."
    TKGDeclare TKG(panelbuttonfont) {} -fallback {tkgbigbold}\
         -vartype font\
	-typelist [list General Fonts Main]\
	 -label "Font on PanelButtons"\
	 -help "Defaults to default big bold font."
    TKGDeclare TKG(menufont) {} -fallback {tkgbig}\
         -vartype font\
	-typelist [list General Fonts Main]\
	 -label "Font on menus"\
	 -help "Defaults to default big font."
    TKGDeclare TKG(labelboxfont) {} -fallback {tkgbigbold}\
         -vartype font\
	-typelist [list General Fonts Main]\
	-label "Font on Label Boxes"\
	 -help "Defaults to default big bold font."
    TKGDeclare TKG(dialogfont) {} -fallback {tkgbig}\
         -vartype font\
	-typelist [list General Fonts Main]\
	-label "Font in dialog boxes"\
	 -help "Defaults to default big font."
    TKGDeclare TKG(textfont) {} -fallback {tkgbig}\
         -vartype font\
	-typelist [list General Fonts Main]\
	-label "Font in screens of text"\
	 -help "Defaults to default big font."
    TKGDeclare TKG(dialogtitlefont) {} -fallback {tkghugebold}\
         -vartype font\
	-typelist [list General Fonts Main]\
	-label "Font in Dialog Box Titles"\
	 -help "Defaults to default Huge bold font."
	  }}	      

proc TKGSetResources {} { uplevel {
    foreach type {"" fixed} {
	foreach size {small medium big huge Huge} {
	    font create tkg${type}${size}\
		-family $TKG(${type}fontfamily) \
		-size $TKG(font${size}size)
	    font create tkg${type}${size}italic\
		-family $TKG(${type}fontfamily) \
		-size $TKG(font${size}size) \
		-slant italic
	    font create tkg${type}${size}bold\
		-family $TKG(${type}fontfamily) \
		-size $TKG(font${size}size) \
		-weight bold
	    font create tkg${type}${size}bolditalic\
		-family $TKG(${type}fontfamily) \
		-size $TKG(font${size}size) \
		-weight bold -slant italic
	}

    }
	    
		
    option add *background                  $TKG(background)
    option add *Button.background           $TKG(background)
    option add *Button.foreground           $TKG(foreground)
    option add *activeBackground            $TKG(activebackground)
    option add *activeForeground            $TKG(activeforeground)
    option add *Tkgbutton.activeBackground  $TKG(butactivebackground)
    option add *Tkgbutton.activeForeground  $TKG(butactiveforeground)
    option add *disabledForeground          $TKG(disabledforeground)
    option add *highlightBackground	    $TKG(background)
    option add *highlightColor              $TKG(highlightcolor)
    option add *Label.foreground	    $TKG(foreground)
    option add *image*foreground            $TKG(buttonforeground)
    option add *image.background            $TKG(buttonbackground)
    option add *text.foreground             $TKG(textforeground)
    option add *msg.background              $TKG(labelboxbackground)
    option add *msg.foreground              $TKG(labelboxforeground)
    option add *text.background             $TKG(textbackground)
    option add *Scrollbar.troughColor       $TKG(scrollbartrough)
    option add *Entry.background            $TKG(entrybackground)

    option add *font             $TKG(generalfont)   widgetDefault
    option add *Menu*font        $TKG(menufont)      widgetDefault
    option add *lbtext.font      $TKG(labelboxfont)  widgetDefault
    option add *view.text.font   $TKG(textfont)      widgetDefault
    option add *message.font     $TKG(dialogfont)    widgetDefault
    option add *title.title.font $TKG(dialogtitlefont) widgetDefault
    option add *TkgButton.font   $TKG(combofont) widgetDefault
}}
