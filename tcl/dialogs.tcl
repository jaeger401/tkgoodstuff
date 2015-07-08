# Procedure to create a dialog with buttons and (optionally) a title (with image if
# wanted), message (box with a message widget), and text (a text widget with
# scrollbar)

proc TKGDialog args {
    global TKG TKG_strings

    set name [lindex $args 0]
    set wmtitle "Notice"
    if [info exists TKG_strings(notice)] { 
	set wmtitle $TKG_strings(notice)
    } 
    set image ""
    set title ""
    if [catch {
	set titlebg $TKG(background)
	set titlefg $TKG(foreground)
	set bitmapfg $TKG(foreground)
	set font $TKG(dialogfont)
    }] {
	set titlebg \#b0b0b0
	set titlefg \#000000
	set bitmapfg \#000000
	set font tkgHuge
    }
    if {[catch {font actual $font}]} {
	set font {helvetica 12}
    }
    set message ""
    set text "-"
    set buttons {}
    set switches {wmtitle image title titlebg titlefg \
		      bitmapfg message text buttons font}
    foreach switch $switches {
	if { [ set i [lsearch $args "-$switch"]] != -1 } {
	    set $switch [lindex $args [expr $i + 1]]
	}
    }
    set oldfocus [focus]
    catch {destroy .$name}
    toplevel .$name 
    grid columnconfigure .$name 0 -weight 1
    wm withdraw .$name
    wm title .$name "$wmtitle"
    wm minsize .$name 20 10
    if { ! ( $image == "" && $title == "" ) } {
	frame .$name.title -background $titlebg -relief raised -bd 1
	grid columnconfigure .$name.title 1 -weight 1
	if { $image != "" } {
	    if [regexp "bitmap (.*)" [SetImage $name-image $image] v v ] {
		set imageoption "-bitmap @$v"
	    } else {
		set imageoption "-image $name-image"
	    }
	    eval label .$name.title.icon $imageoption \
		-foreground $bitmapfg -background $titlebg\
		 -pady 0 -borderwidth 0 -highlightthickness 0
	    grid .$name.title.icon -row 0 -column 0 -padx 20 -pady 6 -sticky nsew
	}
	if { $title != "" } {
	    label .$name.title.title -text "$title" \
		-foreground $titlefg -background $titlebg\
		 -pady 0 -borderwidth 0 -highlightthickness 0
	    grid .$name.title.title -row 0 -column 1 -padx 6 -pady 8 -sticky nsw
	}
	grid .$name.title -row 0 -column 0 -sticky nsew
    }
    if { $message != "" } {
	set textsize [TKGtextsize $message]
	set textwidth [expr ([set w [lindex $textsize 0]] > 80) ? 80: $w]
	set textheight [lindex $textsize 1]
	text .$name.message -relief flat -borderwidth 3 \
	    -width $textwidth -height $textheight -wrap none -font $font
	grid .$name.message -padx 10 -pady 10 -sticky nsew -row 5 -column 0
	.$name.message configure -state normal
	.$name.message insert end "$message"
	.$name.message configure -state disabled
    }
    if { $text  != "-" } {
	frame .$name.view  -relief raised -bd 1
	grid columnconfigure .$name.view 0 -weight 1
	grid rowconfigure .$name.view 0 -weight 1
	text .$name.view.text \
	    -width $TKG(dialogtextwidth) -height $TKG(dialogtextheight) \
	    -takefocus 0 -yscrollcommand ".$name.view.scrollbar set" \
	    -relief sunken -borderwidth 2 -state disabled -font $font
	grid .$name.view.text -row 0 -column 0 -sticky nsew -padx 5 -pady 5
	scrollbar .$name.view.scrollbar -command ".$name.view.text yview"
	grid .$name.view.scrollbar -row 0 -column 1 -sticky nsew -padx 5 -pady 5
	grid .$name.view -row 5 -column 0 -sticky nsew
	.$name.view.text configure -state normal
	.$name.view.text insert end "$text"
	.$name.view.text configure -state disabled
    }
    frame .$name.buttons  -relief raised -bd 1
    set i 0
    foreach button $buttons {
	grid columnconfigure .$name.buttons $i -weight 1
	set buttonname [lindex $button 0]
	button .$name.buttons.$buttonname \
	    -text [lindex $button 1] \
	    -command [lindex $button 2]
	bind .$name.buttons.$buttonname <Key-Return> ".$name.buttons.$buttonname invoke"
	grid .$name.buttons.$buttonname -row 0 -column $i -sticky ns -padx 10
	incr i
    }
    if { [lsearch $args "-nodismiss"] == -1 } {
	grid columnconfigure .$name.buttons $i -weight 1
	button .$name.buttons.dismiss -text Dismiss \
	    -command "destroy .$name; catch \{focus $oldfocus\}"
	bind .$name <Key-Escape>  ".$name.buttons.dismiss invoke"
	bind .$name <Key-Return>  ".$name.buttons.dismiss invoke"
	grid .$name.buttons.dismiss -row 0 -column $i -sticky ns -padx 10
    }
    grid .$name.buttons -row 9 -column 0 -ipadx 12 -ipady 10 -sticky nsew
    grid rowconfigure .$name 5 -weight 1
    grid rowconfigure .$name 0 -weight 0
    grid rowconfigure .$name 9 -weight 0
    catch {focus .$name.buttons.dismiss}
    if { [lsearch $args "-nodeiconify"] == -1 } {
	TKGCenter .$name
    }
    DEBUG "creating popup: .$name"
}

proc TKGtextsize {text} {
    set lines 0
    set width 0
    foreach line [set linelist [split $text "\n"]] {
	if {$width < [set l [string length $line]]} {
	    set width $l
	}
	incr lines
    }
    return [list $width $lines]
}

proc TKGTrace {info} {
    TKGDialog tkgtrace \
	-title "Stack Trace"\
	-text "$info"
}

proc TKGNotice {string {flag ""}} {
    TKGDialog tkgnotice\
	-title "tkgoodstuff Notice:"\
	-message $string
}

proc TKGError {string {flag ""}} {
    global errorInfo TKG
    set TKG(error) 1
    set info $errorInfo
# USE THIS WHEN ERROR MECHANISM IS PRODUCING ERRORS
    puts "$string\n$info";return
    set c {TKGDialog tkgerror\
	       -image warning\
	       -title "tkgoodstuff Error:"\
	       -message $string}
    set b [list [list prefs "Preferences\nManager" TKGPreferences]]
    if ![Empty $info] {
	lappend b [list trace "Stack Trace" [list TKGTrace $info]]
    }
    append c " -buttons [list $b]"
    eval $c
    if [string match exit $flag] {
	tkwait window .tkgerror
	TKGQuit
    }
}

proc bgerror err {TKGError $err exit}

TKGAddToHook TKG_postedhook-main-panel {proc bgerror err {TKGError $err}}

proc TKGHelp {} {
    global TKG
    set message "
tkgoodstuff version $TKG(version), $TKG(releasedate),
copyright 1995, 1996, and 1997 Mark Crimmins (markcrim@umich.edu).

Documentation exists only in html form.  Launch the internal help
browser or $TKG(browser) to view documentation on your local system,
or launch $TKG(browser) to view the latest documentation on the
tkgoodstuff web page.
"

    TKGDialog tkghelp\
	-wmtitle "tkgoodstuff help"\
	-title "tkgoodstuff Help"\
	-buttons [subst {
            { localdoc-internal
		\"Internal\nbrowser\" 
		{ cd $TKG(libdir)
                 exec ./tcl/Help.tcl $TKG(libdir)/doc/toc.html &
                 destroy .tkghelp
                }
	    }
            { localdoc-tkgbrowser
		\"$TKG(browser)\"
		{ TKGBrowse file:$TKG(libdir)/doc/index.html
                 destroy .tkghelp
                }
	    }
	    { webdoc-tkgbrowser
		\"$TKG(browser)\n(WWW)\" 
		{ TKGBrowse $TKG(webpage)
                 destroy .tkghelp
                }
	    }
	}] \
    -message $message
}

