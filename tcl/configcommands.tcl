#################################
# Procedures called in rc files:
#

proc Client {name} {
    global TKG
    lappend TKG(clients) $name
    TKGAddToHook TKG_createmainpanel \
	"if !\[Empty \[info procs ${name}CreateWindow\]\] ${name}CreateWindow"
}

set TKG(switches,ClientButton1) {
    {iconside {}\
	 {-label "Side of icon on button" -vartype optionMenu\
	      -optionlist {left right top bottom background} \
	      -help {Leave unset to use context-sensitive default}
	 }
	 Misc
     }
    {ignore  0 {-label {Ignore general preferences for no labels\
and no icons} -vartype boolean} Misc}
    {font {} {-label {Font of text on button} -vartype font} Misc}
    {tilefile {} {-label {Background tile (file)}} Misc}
    {relief {} \
	 {-label {Normal relief of button} -vartype optionMenu\
	      -optionlist {flat raised}
	 }
	 Misc
    }
}

set TKG(switches,ClientButton2) {
    {usebutton2 1 {-label {Mouse button 2 executes unix command\
even when button is depressed} -vartype boolean} Misc}
    {staydown 1 {-label {Button stays down until command is finished} -vartype boolean} Misc}
    {trackwindow 0 {-vartype boolean\
	 -label {Fvwm button behavior} -help {\
If tkgoodstuff is used as an fvwm module, the button will stay down whenever
there exists a window of the given name.}} Fvwm}
    {windowname {} {-label {Windowname of the window produced by the command} -help \
{If tkgoodstuff is used as an fvwm module, clicking on a sunken button
will take you to the window of this name.  Defaults to the name of the 
program in the unix command.}} Fvwm}
}

set TKG(switches,ClientButton3) {
    {foreground {} {-label Foreground -vartype color} Colors}
    {background {} {-label Background -vartype color} Colors}
    {activeforeground {} {-label {Active foreground} -vartype color} Colors}
    {activebackground {} {-label {Active background} -vartype color} Colors}
}

set TKG(switches,ClientButton4) {
    {text {} {-label {Text on button}} Main}
    {imagefile {} {-label {Icon (file)}} Main}
}

set TKG(switches,ClientButton5) {
    {nolabel 0 {-vartype boolean -label "Don't use a text label"} Misc}
    {noicon 0 {-vartype boolean -label "Don't use an icon"} Misc}
}

set TKG(switches,Button) [concat $TKG(switches,ClientButton1) \
			      $TKG(switches,ClientButton2) \
			      $TKG(switches,ClientButton3) \
			      $TKG(switches,ClientButton4) \
			      {
				  {exec {} {-label {Unix command} -scrollbar 1} Main}
				  {command {} {-label {Tcl command} -scrollbar 1} Advanced}
				  {balloon {} {-label {Text in help balloon}} Advanced}
			      }]

proc Button args {
    set name [join $args ~]
    TKGAddToHook TKG_createmainpanel \
	"eval \[concat TKGMakeButton $name \[TKGGetArgs Button $name]]"
}

set TKG(switches,PanelButton) {
    {panelname {} {-label {Name of panel (if not the same as the button name)}} Main}
    {iconside {}\
	 {-label "Side of icon on button" -vartype optionMenu\
	      -optionlist {left right top bottom} \
	      -help {Leave unset to use context-sensitive default}
	 }
	 Misc
     }
    {relief {} \
	 {-label {Normal relief of button} -vartype optionMenu\
	      -optionlist {flat raised}
	 }
	 Misc
    }
    {ignore  0 {-label "Ignore general preferences for no labels\
and no icons" -vartype boolean} Misc}
    {foreground {} {-label Foreground} Colors}
    {background {} {-label Background} Colors}
    {activeforeground {} {-label {Active foreground}} Colors}
    {activebackground {} {-label {Active background}} Colors}
    {text {} {-label {Text on button (if not the same as the button name)}} Main}
    {imagefile {} {-label {Icon (file)}} Main}
    {font {} {-label {Font of text on button}} Misc}
}

proc PanelButton args {
    global TKG
    set label $args
    set name [join $args ~]
    set args [TKGGetArgs PanelButton $name]
    set i [expr [lsearch $args -panelname] + 1]
    if [Empty [set panelname [lindex $args $i]]] {
	set args [lreplace $args [expr $i - 1] $i]
	set panelname $name
    }
    set i [expr [lsearch $args -font] + 1]
    if [Empty [lindex $args $i]] {
	set args [lreplace $args $i $i $TKG(panelbuttonfont)]
    }
    set panelname [join [string tolower $panelname] ~]
    lappend args -command(normal) \
	"TKGPanelButtonInvoke $name $panelname-panel"
    TKGAddToHook TKG_createmainpanel\
	"TKGMakeButton [concat $name $args]"
}

set TKG(switches,PutPanel) {
    {geometry {} {-label "Panel position" -help {Determines the screen position of the
panel.  For example, use +40+30 to put the upper left corner 40 
pixels from the left edge of the screen and 30 below the top.  Use
-0-0 to put the lower right corner at the lower right corner of the
screen.}}}
}

proc PutPanel args {
    set name [string trim [join $args ~]]
    set args [TKGGetArgs PutPanel $name]
    TKGAddToHook TKG_postedhook-main-panel [concat TKGPanelPlace $name $args]
}
    
set TKG(switches,LabelBox) {
    {text {} {-text {Text:} -help {Use "\\n" for additional lines.}}}
}

proc LabelBox args {
    set name [join $args ~]
    set pargs [TKGGetArgs LabelBox $name]
    set i [expr 1 + [lsearch $pargs -text]]
    if [Empty [lindex $pargs $i]] {
	set pargs [lreplace $pargs $i $i $args]
    }
    global TKG
    if ![info exists TKG(labnum)] {
	set TKG(labnum) 0
    } else {
	incr TKG(labnum)
    }
    set name tkglab$TKG(labnum)
    TKGAddToHook TKG_createmainpanel [subst {
	TKGLabelBox [concat $name $pargs]
	TKGGrid \$${name}_window
    }]
}

proc Fill {} {
    TKGAddToHook TKG_createmainpanel DoFill
}    

set TKG(switches,Stack) {
    {orientation {} {-label Orientation -vartype optionMenu \
			       -optionlist {vertical horizontal}}
    }
    {borderwidth 0 {-label {Border width}}}
    {color {} {-label {Color of border}}}
}

proc Stack args {
    set name [join $args ~]
    set args [TKGGetArgs Stack $name]
    TKGAddToHook TKG_createmainpanel "StartStack $args"
}

proc EndStack {} {
    TKGAddToHook TKG_createmainpanel "FinishStack"
}

set TKG(switches,Panel) {
    {orientation {} \
	 {-label Orientation -vartype radio -radioside top\
	      -radiolist {{vertical vertical} {horizontal horizontal}
	      }
	 }
    }
    {borderwidth {} {-label {Border width}}}
    {color {} {-label {Color of Border}}}
    {title {} {-label {Title (for window manager) of panel window}}}
    {iconside {} {
	-label {Default side of icons on buttons in the panel}\
	    -help {Leave unset to use (context-sensitive) defaults.}\
	    -vartype optionMenu\
	    -optionlist {left right top bottom}
	}
    }
}

proc Panel args {
    set configname [join $args ~]
    set name [string tolower $configname]-panel
    set args [TKGGetArgs Panel $configname]
    global TKG TKG_prevpanel
    set TKG_prevpanel($name) $TKG(currentpanel)
    set TKG(currentpanel) $name
    TKGAddToHook TKG_createmainpanel [subst {TKGStartPanel $name $args}]
}

proc EndPanel {} {
    global TKG TKG_prevpanel
    TKGAddToHook TKG_createmainpanel "TKGEndPanel"
    set TKG(currentpanel) $TKG_prevpanel($TKG(currentpanel))
}

proc SystemConfig {} {
    global TKG
    set f $TKG(libdir)/system-tkgrc
    if { [ file exists $f ] && [ file readable $f ] } {
	uplevel 1 "source $f"
    }
}

