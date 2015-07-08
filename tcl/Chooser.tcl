#  Chooser, a Client for TkGoodstuff
#
#    By Eric Kahler (ekahler@mars.superlink.net) 
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

proc ChooserDeclare {} {
    TKGDeclare ChooserList {$TKG(libdir)/sample-rc} -typelist [list Chooser]\
	-label "Space-separated list of configuration files (or a directory of configuration files)"
    TKGDeclare ChooserButtons 1 -typelist [list Chooser] -vartype boolean\
	-label "Produce buttons (rather than just inserting menu items)"
}

proc ChooserCreateWindow {} {
    global TKG Chooser-params ChooserList ChooserButtons 
    global Name File x

    set x 0

    uplevel {
	if $ChooserButtons {
	    StartStack -orientation vertical
	    TKGLabelBox chooserlabel -text "Choose tkgoodstuff\nConfiguration:"
	}
    }
    if [file isdirectory $ChooserList] {
	if ![file readable $ChooserList] {
	    TKGError "Chooser: You don't have read permission for directory $ChooserList." exit
	} else {
	    foreach File [glob -nocomplain $ChooserList/*] {
		if ![file readable $File] {
		    TKGError "You don't have read permission for file $File."
		} else {
		    set Name [file tail $File]	
		    incr x
		    uplevel {
			if {$x==1} {TKGPopupAddClient Chooser}
			if {$ChooserButtons} {


			    TKGMakeButton $x -text(norm) $Name \
				-command(norm) "choice $File" \
				-mode norm }
			
			.tkgpopup.chooser add command -label $Name -command "choice $File"
		    }
		}
	    }
	}
    } else { 
	foreach File $ChooserList {
	    if [file exists $File] {
		if ![file readable $File] {
		    TKGError "You don't have read permission for file $File."
		    return
		} else {
		    set Name [file tail $File]
		    incr x
		    uplevel {
			if {$x==1} {TKGPopupAddClient Chooser}
			if {$ChooserButtons} {
			    TKGMakeButton $x -text(norm) $Name \
				-command(norm) "choice $File" \
				-mode norm }
			.tkgpopup.chooser add command -label $Name -command "choice $File" 
		    }
		}
	    }   
	}
    }
    uplevel {
	if $ChooserButtons {
	    FinishStack
	}
    }
}


proc choice { CnfgFile  } {
    global argv Fvwm TKG

    if ![catch {format "%d %d" [lindex $argv 0] [lindex $argv 1]}] {
	# tkgoodstuff was called as an Fvwm Module 
	if { [lsearch $TKG(clients) Fvwm] == -1 } {
	    # Communication with Fvwm is not yet established
	    Client Fvwm
	}
	fvwm send $Fvwm(outid) "[tk appname] -f $CnfgFile"
	TKGQuit
    } else {
	set cmdlinepos [expr [ lsearch $argv "-f" ] + 1]
	
	if { $cmdlinepos != 0 } {
	    # tkgoodstuff started from commandline with arguments.
	    set argv [ lreplace $argv $cmdlinepos $cmdlinepos $CnfgFile ]
	    
	    # TKGRestart localized, doesn't copy present geometry
	    catch {close $TKG(logfileid)}
	    if ![Empty [info script]] { 
		eval exec [info script] $argv &
	    } else {
		eval exec tkgoodstuff $argv &
	    }	        
	    TKGQuit
	} else {
	    # tkgoodstuff started from command line with no arguments
	    
	    # TKGRestart localized, doesn't copy present geometry
	    catch {close $TKG(logfileid)}
	    if ![Empty [info script]] { 
		eval exec [info script] [list "-f" "$CnfgFile"] &
	    } else {
		eval exec tkgoodstuff [list "-f" "$CnfgFile"] &
	    }	        
	    TKGQuit
	}    
    }
}
DEBUG "Loaded Chooser.tcl"
