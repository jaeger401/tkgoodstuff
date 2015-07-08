#  WatchDog, a Client for TkGoodstuff
#
#    By Eric Kahler (ekahler@mars.superlink.net) 
#       and Mark Crimmins (markcrim@umich.edu) 
#    Copyright (C) 1996; all rights reserved
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation License version 2.
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.  For a copy of the 
#    GNU General Public License write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#    At the time of this copy-left the GNU General Public License can
#    also be obtained via FTP from wuarchive.wustl.edu/systems/gnu/COPYING

proc WatchDogDeclare {} {
    set Prefs_taborder(:Clients,WatchDog) "Misc Button CustomDisplay"
    set Prefs_taborder(:Clients,WatchDog,Button) "Misc Icons Colors"
    TKGDeclare WatchDog(File) {/var/log/messages} -typelist [list Clients WatchDog Misc]\
	-label "File to watch"
    TKGDeclare WatchDog(update_interval) 30 -typelist [list Clients WatchDog Misc]\
	-label "Check every __ seconds"
    TKGDeclare WatchDog(nobeep) 0 -typelist [list Clients WatchDog Misc]\
	-vartype boolean\
	-label "Do not beep"
    TKGDeclare WatchDog(CustomDisplay) 0 -typelist [list Clients WatchDog Misc]\
	-vartype boolean\
	-label "Display file with custom-style display"
    TKGDeclare WatchDog(autoreset) 0 -typelist [list Clients WatchDog Misc]\
	-vartype boolean\
	-label "Auto-reset (after alert, go back to no-alert mode after the\
checking interval)"
    TKGDeclare WatchDog(autoview) 0  -typelist [list Clients WatchDog Misc]\
	-vartype boolean\
	-label "Pop-up a viewing window at alert"
    TKGDeclare WatchDog(nobutton) 0 -typelist [list Clients WatchDog Button Misc]\
	-vartype boolean\
	-label "Do not produce a button"
    ConfigDeclare WatchDog ClientButton1 WatchDog [list Clients WatchDog Button]
    ConfigDeclare WatchDog ClientButton5 WatchDog [list Clients WatchDog Button]

    TKGDeclare WatchDog(change_text) {[file tail $WatchDog(File)]}\
	-typelist [list Clients WatchDog Button Misc]\
	-label "Changed text"
    TKGColorDeclare WatchDog(change_foreground) \#7fff00 \
	[list Clients WatchDog Button Colors] \
	"Changed foreground"
    TKGColorDeclare WatchDog(change_background) {} \
	[list Clients WatchDog Button Colors] \
	"Changed background" $TKG(buttonbackground)
    TKGColorDeclare WatchDog(change_activeforeground) \#7fff00 \
	[list Clients WatchDog Button Colors] \
	"Changed activeforeground"

    TKGDeclare WatchDog(nochange_text) {[file tail $WatchDog(File)]}\
	-typelist [list Clients WatchDog Button Misc] \
	-label "Text for no change"
    TKGColorDeclare WatchDog(nochange_foreground) {} \
	[list Clients WatchDog Button Colors] \
	"Foreground for no change" $TKG(buttonforeground)
    TKGColorDeclare WatchDog(nochange_background) {} \
	[list Clients WatchDog Button Colors] \
	"Background for no change" $TKG(buttonbackground)
    TKGColorDeclare WatchDog(nochange_activeforeground) {} \
	[list Clients WatchDog Button Colors] \
	"Activeforeground for no change" $TKG(buttonforeground)

    TKGDeclare WatchDog(gone_text) {[file tail $WatchDog(File)]}\
	-typelist [list Clients WatchDog Button Misc] \
	-label "Text for no file"
    TKGColorDeclare WatchDog(gone_foreground) {} \
	[list Clients WatchDog Button Colors] \
	"Foreground for no file" $TKG(disabledforeground)
    TKGColorDeclare WatchDog(gone_background) {} \
	[list Clients WatchDog Button Colors] \
	"Background for no file" $TKG(buttonbackground)
    TKGColorDeclare WatchDog(gone_activeforeground) {} \
	[list Clients WatchDog Button Colors] \
	"Activeforeground for no file" $TKG(disabledforeground)

    TKGDeclare WatchDog(change_image) {filefull.xpm}\
	-typelist [list Clients WatchDog Button Icons] \
	-label "Image for a change"
    TKGDeclare WatchDog(nochange_image) {fileempty.xpm}\
	-typelist [list Clients WatchDog Button Icons] \
	-label "Image for no change"
    TKGDeclare WatchDog(gone_image) {filegone.xpm}\
	-typelist [list Clients WatchDog Button Icons] \
	-label "Image for no file"

    TKGDeclare WatchDog(Position) +0-10 \
	-typelist [list Clients WatchDog CustomDisplay] \
	-label "Screen position"
    TKGDeclare WatchDog(Height) 2 \
	-typelist [list Clients WatchDog CustomDisplay] \
	-label "Height in rows"
    TKGDeclare WatchDog(Width) {120}\
	-typelist [list Clients WatchDog CustomDisplay] \
	-label "Width in columns"
    TKGDeclare WatchDog(ButtonSide) left \
	-typelist [list Clients WatchDog CustomDisplay] \
	-label "Side for button"
    TKGDeclare WatchDog(ScrollbarSide) left \
	-typelist [list Clients WatchDog CustomDisplay] \
	-label "Side for Scrollbar"
    TKGDeclare WatchDog(ScrollbarWidth) 4m -typelist \
	[list Clients WatchDog CustomDisplay] \
	-label "Scrollbar width (pixels)"
    TKGDeclare WatchDog(Font) "" -fallback tkgmedium \
	-typelist [list Clients WatchDog CustomDisplay] \
	-label "Font"
}

proc WatchDogCreateWindow {} {
    if [TKGReGrid WatchDog] return
    global WatchDog-params TKG WatchDog
    
    uplevel {
	catch {set WatchDog(File) [glob $WatchDog(File)]}
	set WatchDog(initialize_offset) $WatchDog(update_interval)
	set  WatchDog(FileSize) 0
	if [file exists $WatchDog(File)] {
	    if [file isdirectory $WatchDog(File)] {
		if ![file readable $WatchDog(File)] {
		    TKGError "Can't Watch $WatchDog(File) because you don't have read permission."
		    return
		}
		set WatchDog(FileSize) [exec /bin/ls -l $WatchDog(File) | sum ]
	    } else {
		catch {set WatchDog(FileSize) [file size $WatchDog(File)]}
	    }
	}
	
	if !$WatchDog(nobutton) {

	    if { $WatchDog(nolabel) } {
		set WatchDog(change_text) ""
		set WatchDog(nochange_text) ""
		set WatchDog(gone_text) ""
	    }
	    
	    if [file exists $WatchDog(File)] {
		set mode nochange
	    } else {
		set mode gone
	    }
	    TKGMakeButton WatchDog -text(change) $WatchDog(change_text) \
		-foreground(change) $WatchDog(change_foreground) \
		-activeforeground(change) $WatchDog(change_activeforeground) \
		-background(change) $WatchDog(change_background) \
		-command(change) WatchDog-Display \
		-text(nochange) $WatchDog(nochange_text) \
		-balloon(nochange) "No change in\n$WatchDog(File)" \
		-balloon(change) "$WatchDog(File)\nhas changed" \
		-balloon(gone) "File \n$WatchDog(File) does not exist" \
		-foreground(nochange) $WatchDog(nochange_foreground) \
		-activeforeground(nochange) $WatchDog(nochange_activeforeground) \
		-background(nochange) $WatchDog(nochange_background) \
		-command(nochange) WatchDog-Display \
		-text(gone) $WatchDog(gone_text) \
		-foreground(gone) $WatchDog(gone_foreground) \
		-activeforeground(gone) $WatchDog(gone_activeforeground) \
		-background(gone) $WatchDog(gone_background) \
		-command(gone) WatchDog-Display\
		-mode $mode
	    
	    if !$WatchDog(noicon) {
		SetImage WatchDog_change_image $WatchDog(change_image)
		SetImage WatchDog_nochange_image $WatchDog(nochange_image)
		SetImage WatchDog_gone_image $WatchDog(gone_image)
		TKGButton WatchDog -image(change) WatchDog_change_image \
		    -image(nochange) WatchDog_nochange_image \
		    -image(gone) WatchDog_gone_image \
		    -iconside $WatchDog(iconside)\
		    -relief $WatchDog(relief)
	    }
	    
	    
	    bind [set WatchDog-params(pathname)] <2> \
		{ WatchDog-Set-Normal }
	}
	
	uplevel #0 {
	TKGPeriodic WatchDog-Update $WatchDog(update_interval) \
	    $WatchDog(initialize_offset) WatchDog-Update
    }
}
}

proc WatchDog-Update {} {
    global WatchDog-params WatchDog TKG

    if { ![file exists $WatchDog(File)] || [winfo exists .watchdog_display]} return

    if !$WatchDog(nobutton) {
	if { [WatchDog-Test-File] && !$TKG(nonotices) } {
	    if {[set WatchDog-params(mode)] != "change"} {
		TKGButton WatchDog -mode change
		if {! ( $WatchDog(nobeep) || $TKG(nobeep) ) } {
		    catch { bell; bell }
		}
		if $WatchDog(autoreset) {
		    TKGPeriodic WatchDog-reset $WatchDog(update_interval) \
			$WatchDog(update_interval) WatchDog-Reset
		}
	    }
	    if $WatchDog(autoview) WatchDog-Display
	} elseif { [set WatchDog-params(mode)] != "nochange" } {
	    TKGButton WatchDog -mode nochange
	}
    } elseif { [WatchDog-Test-File] } {
	if { !$TKG(nonotices) } {
	    if {! ( $WatchDog(nobeep) || $TKG(nobeep) ) } {
		catch { bell; bell }
	    }
	    if $WatchDog(autoview) WatchDog-Display
	}
    }
}

proc WatchDog-Reset {} {
    global WatchDog-params
    TKGPeriodicCancel WatchDog-reset
    TKGButton WatchDog -mode nochange
}

proc WatchDog-Test-File {} {
    global WatchDog WatchDog-params

    if [file isdirectory $WatchDog(File)] {
	set filesize [exec /bin/ls -l $WatchDog(File) | sum ]
    } else {
	set filesize [file size $WatchDog(File)]
    }
    if {$filesize == 0} {return 0}
    if {$filesize != $WatchDog(FileSize)} {
	set WatchDog(FileSize) $filesize
	return 1
    } elseif $WatchDog(nobutton) { 
	return 0 
    } else { return [string match [set WatchDog-params(mode)] change] }
}


proc WatchDog-Display {} {
    global WatchDog

    if { ![file exists $WatchDog(File)] } {
        TKGError "Cannot display $WatchDog(File) because it does not exist."
	return
    } 
    if { ![file readable $WatchDog(File)] } {
        TKGError "Cannot display $WatchDog(File) because you do not have read permission."
	return
    } 
    
    if !$WatchDog(nobutton) {TKGButton WatchDog -mode nochange}

    if { $WatchDog(CustomDisplay) } {
	
	set WatchDog(textwidget) .watchdog_display.text
	catch {destroy .watchdog_display}
	toplevel .watchdog_display
	wm withdraw .watchdog_display
	wm title .watchdog_display "WatchDog"
	wm iconname .watchdog_display "WatchDog"
	
	frame .watchdog_display.buttons
	pack  .watchdog_display.buttons -side $WatchDog(ButtonSide) -pady 1m -padx 1m
	button .watchdog_display.buttons.goaway -text "Dismiss" -command Watch-Display-End
	pack .watchdog_display.buttons.goaway \
	    -side $WatchDog(ButtonSide) 
	text .watchdog_display.text -relief sunken -bd 2 \
	    -yscrollcommand ".watchdog_display.scroll set" \
	    -setgrid 1 -height $WatchDog(Height) -width $WatchDog(Width) \
	    -font $WatchDog(Font)
	scrollbar .watchdog_display.scroll -command ".watchdog_display.text yview" \
	    -width $WatchDog(ScrollbarWidth)
	pack .watchdog_display.scroll -side $WatchDog(ScrollbarSide) -fill y
	pack .watchdog_display.text -expand yes -fill both
    } else {
	TKGDialog watchdog_display -title "WatchDog" -text "" \
	    -buttons { {goaway Dismiss Watch-Display-End} } -nodismiss -nodeiconify
	set WatchDog(textwidget) .watchdog_display.view.text
    }

    focus .watchdog_display.buttons.goaway
    WatchDog-Display-Get
    if { $WatchDog(CustomDisplay) } { 
    	wm deiconify .watchdog_display
	update
	wm geometry .watchdog_display $WatchDog(Position)
    } else { TKGCenter .watchdog_display }

    uplevel #0 {
    TKGPeriodic Display-Update $WatchDog(update_interval) 0 \
	WatchDog-Display-Update
}
}

proc WatchDog-Display-Update {} {
    global WatchDog
    
    if [WatchDog-Test-File] {
	if { $WatchDog(nobutton) || $WatchDog(autoview) } { 
	    TKGPeriodicCancel Display-Update
	    WatchDog-Display 
	}
	WatchDog-Display-Get
    }
}

proc WatchDog-Display-Get {} {
    global WatchDog
    $WatchDog(textwidget) configure -state normal
    $WatchDog(textwidget) delete 1.0 end
    if [file isdirectory $WatchDog(File)] {
	$WatchDog(textwidget) insert end [exec /bin/ls -l $WatchDog(File)]
    } else {	
	set id [open $WatchDog(File) RDONLY]
	$WatchDog(textwidget) insert end [read $id]
	close $id
    }
    $WatchDog(textwidget) see end
    $WatchDog(textwidget) configure -state disabled
}

proc Watch-Display-End {} {
    destroy .watchdog_display
    TKGPeriodicCancel Display-Update
}

proc WatchDog-Set-Normal {} {
    global WatchDog

    catch {set WatchDog(FileSize) [file size $WatchDog(File)]}
    TKGButton WatchDog -mode nochange
}

DEBUG "Loaded WatchDog.tcl"
