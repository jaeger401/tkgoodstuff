# Biff (mail-checking, mailer-launching) Client Tcl code for tkgoodstuff

proc BiffDeclare {} {
    set Prefs_taborder(:Clients,Biff) "MailboxList Mailboxes Button Misc MH"
    set Prefs_taborder(:Clients,Biff,Button) "Misc Icons Colors Fvwm"
    TKGDeclare Biff(mailboxlist) {{Mailbox INBOX}} \
	-vartype biff -nolabel 1 -nodefault 1\
	-typelist [list Clients Biff MailboxList]
    TKGDeclare Biff(mailer) xmh \
	-typelist [list Clients Biff Misc]\
	-label "Command to launch email program"
    ConfigDeclare Biff ClientButton1 Biff [list Clients Biff Button]
    ConfigDeclare Biff ClientButton2 Biff [list Clients Biff Button]
    ConfigDeclare Biff ClientButton5 Biff [list Clients Biff Button]
    TKGDeclare BiffMH(mh_path) ""\
	-typelist [list Clients Biff MH]\
	-label "Full path to MH programs (ie: scan, pick)"\
	-help "By default we hunt semi-intelligently."
    TKGDeclare BiffMH(scan_params) "-header"\
	-typelist [list Clients Biff MH]\
	-label "Additional arguments to MH scan program (ie: -form scan.default)"
    TKGDeclare BiffMH(rcvstore) 1 \
	-vartype boolean\
	-typelist [list Clients Biff MH]\
	-label "MH's rcvstore is used"\
	-help "If rcvstore is used, we use MH's own method of keeping track of unseen messages."
    TKGDeclare Biff(count) 1\
	-typelist [list Clients Biff Misc]\
	-vartype boolean\
	-label "New-mail label contains number of messages in mailbox (when single mailbox is used)"
    TKGDeclare Biff(menufont) ""\
	-vartype font\
	-typelist [list Clients Biff Misc]\
	-label "Font for menu of mailboxes (when multiple mailboxes are used)"
    TKGDeclare Biff(tearoff) 0\
	-typelist [list Clients Biff Misc]\
	-vartype boolean\
	-label "Menu of mailboxes can be torn-off (when multiple mailboxes are used)"
    TKGDeclare Biff(usemenu) 0\
	-typelist [list Clients Biff Misc]\
	-vartype boolean\
	-label "Instead of usual button, include menu of mailboxes on panel"
    TKGDeclare Biff(nomail_image) {%biffno}\
	-typelist [list Clients Biff Button Icons]\
	-label "Icon for no mail"
    set Biff(alertlevels) {white green yellow red}
    foreach level $Biff(alertlevels) {
	TKGDeclare Biff($level,image) "%biff$level"\
	    -typelist [list Clients Biff Button Icons]\
	    -label "Icon for new mail: $level alert"
    }

    TKGColorDeclare Biff(newmailforeground) #7fff00 \
	[list Clients Biff Button Colors] \
	"Button foreground: new mail"
    TKGColorDeclare Biff(newmailbackground) {} \
	[list Clients Biff Button Colors] \
	"Button background: new mail" \
	$TKG(buttonbackground)
    TKGColorDeclare Biff(nomailforeground) {} \
	[list Clients Biff Button Colors] \
	"Button foreground: no mail" \
        $TKG(buttonforeground)
    TKGColorDeclare Biff(nomailbackground) {}\
	[list Clients Biff Button Colors] \
	"Button background: no mail" \
	$TKG(buttonbackground)
}

proc BiffUpdate {f} {
    global Biff TKG Biff_newmail
    TKGPeriodicCancel BiffUpdate$f
    switch [[join [list Biff $Biff($f,method) Test] ""] $f] {
	nochange {
	    TKGPeriodic BiffUpdate$f \
		$Biff($f,update_interval) $Biff($f,update_interval) "BiffUpdate $f"
	    return
	} 1 {
	    set Biff_newmail($f) 1
	    set newmail 1
	    Biff3MenuConfig $f 1
	    if { ($Biff($f,frm) && ! $TKG(nonotices)) } { 
		BiffDoFrm $f
	    }
	} 0 {
	    catch {unset Biff_newmail($f)}
	    Biff3MenuConfig $f 0
	}
    }
    BiffSetAlert
    if [info exists newmail] {BiffNewMailStuff $f}
    TKGPeriodic BiffUpdate$f \
	$Biff($f,update_interval) $Biff($f,update_interval) "BiffUpdate $f"
}

proc BiffSetAlert {} {
    global Biff Biff_newmail Biff-params
    if $Biff(usemenu) return
    foreach level $Biff(alertlevels) {
	foreach mb [array names Biff_newmail] {
	    if {$Biff($mb,alertlevel) == $level} {
		set highest $level
	    }
	}
    }
    if [info exists highest] {
	if ![In [image names] Biff_$highest] {
	    SetImage Biff_$highest $Biff($highest,image)
	}
	set Biff-params(image,newmail) Biff_$highest
	TKGButton Biff -mode newmail
    } else {
	if {[set Biff-params(mode)] != "nomail" } {
	    TKGButton Biff -mode nomail
	}
    }
}

proc BiffNewMailStuff {f} {
    global TKG Biff
    if { ! ( $Biff($f,nobeep) || $TKG(nobeep) ) } {
	# percent, pitch, duration
	TKGBell \
	    1 \
	    [expr 1.1 + (.1*[lsearch $Biff(alertlevels) $Biff($f,alertlevel)])]\
	    3
    }
    if ![Empty $Biff($f,newmailevent)] {
	eval exec $Biff($f,newmailevent) &
    }
}

proc BiffIgnore {} {
    global Biff
    foreach f $Biff(mailboxes) { 
	BiffIgnoreFolder $f 
    }
    TKGButton Biff -mode nomail
}

proc BiffIgnoreFolder {f} {
    global Biff Biff_newmail
    [join [list Biff $Biff($f,method) Ignore] ""] $f
    catch {unset Biff_newmail($f)}
    BiffSetAlert
    if [winfo exists .biff3menu] {
	Biff3MenuConfig $f 0
    }
}

proc Biff_3 {x y} {
#    BiffUpdate
    global Biff Biff-params
    [set Biff-params(pathname)] configure -state normal
    if {[llength $Biff(mailboxes)] == 1} {
	BiffDoFrm [lindex $Biff(mailboxes) 0]
	return
    } 
    eval tk_popup .biff3menu [TKGPopupLocate .biff3menu $x $y]
    raise .biff3menu
    focus .biff3menu
}

proc Biff3MenuConfig {f new} {
    if ![winfo exists .biff3menu] return
    global Biff
    if $new {
	.biff3menu entryconfigure \
	    [expr [lsearch $Biff(mailboxes) $f] + \
		 ($Biff(tearoff) && ! $Biff(usemenu))]\
	    -foreground $Biff(newmailforeground) \
	    -activeforeground $Biff(newmailforeground) 
    } else {
	.biff3menu entryconfigure \
	    [expr [lsearch $Biff(mailboxes) $f] + \
		 ($Biff(tearoff) && ! $Biff(usemenu))]\
	    -foreground $Biff(nomailforeground) \
	    -activeforeground $Biff(nomailforeground)
    }
}

proc BiffExecMailer {} {
    global Biff
    if !$Biff(usemenu) {
	TKGbuttonInvoke [set Biff-params(pathname)]
    } else {
	exec $Biff(mailer) &
    }
}

proc BiffDoFrm {f} {
    global Biff TKG Biff_strings Biff-params
    if {![Empty $Biff($f,frm_instead)]} {
	regsub -all -nocase @mailbox@ $Biff($f,frm_instead) \
	    [TKGDecode $f] cmd
	if {[string match "Tcl *" $cmd]} {
	    after 0 [list eval [string range $cmd 4 end]]
	} elseif {[string match exmh $cmd]} {
	    BiffMHExmh $f
	} else {
	    eval exec $cmd &
	}
	return
    }
    set ww biff_frm_$f
    TKGDialog $ww \
	-font tkgfixedbig\
	-image letters \
	-wmtitle $Biff_strings(mail) \
	-title "$Biff_strings(mail): [TKGDecode $f]" \
	-text "Getting list of messages . . ."\
	-nodismiss \
	-nodeiconify \
	-buttons [list \
		      [list launch $Biff_strings(readmail) \
			   "destroy .$ww; BiffExecMailer"\
			  ]\
		      [list rescan Rescan \
			   "BiffDoFrm $f"\
			  ]\
		      [list dismiss $Biff_strings(dismiss)\
			   "destroy .$ww"\
		      ]
		 ]

    set w .$ww.view.text
    $w configure -state disabled
    TKGCenter .$ww
    if {"$Biff($f,frm_command)" != ""} {
	catch { eval exec $Biff($f,frm_command) | cut -c 1-80 } text
	if ![winfo exists $w] return
	$w configure -state normal
	$w delete 1.0 end
	$w insert end $text
    } else {
	if ![Empty [info procs [join [list Biff $Biff($f,method) Scan] ""]]] {
	    set frmlist [[join [list  Biff $Biff($f,method) Scan] ""] $f]
	} else {
	    if ![file exists $Biff($f,folder)] {
		set frmlist ""
	    } else {
		set frmlist [BiffScanHeaders frm $f]
	    }
	}
	if ![winfo exists $w] return
	$w configure -state normal
	$w delete 1.0 end
	if {[llength $frmlist] == 0} {
	    $w insert end $Biff_strings(frm_nomail)
	} elseif [string match [lindex $frmlist 0] error] {
	    TKGError [lindex $frmlist 1]
	    return
	} else {
	    foreach l $frmlist {
		if [lindex $l 2] {
		    set new "N"
		} else {
		    set new " "
		}
		if ![winfo exists $w] return
		$w insert end "[format {%3d %1s %-25s %s} \
                  [lindex $l 3] $new\
		  [string range [lindex $l 0] 0 24]\
		  [string range [lindex $l 1] 0 45]]\n"\
		    msg_[lindex $l 3]
		$w tag bind msg_[lindex $l 3] <Enter> [subst {
		    $w tag configure msg_[lindex $l 3] -background $Biff(frm_selbg)
		}]
		$w tag bind msg_[lindex $l 3] <Leave> [subst {
		    $w tag configure msg_[lindex $l 3] -background $TKG(textbackground)
		}]
		$w tag bind msg_[lindex $l 3] <1>\
		    "BiffDisplayMessage $f [lindex $l 3]"
	    }
	}
    }
    $w configure -state disabled
    $w see end
    BiffIgnoreFolder $f
}

proc BiffDisplayMessage {f num} {
    global Biff
    if [winfo exists .biff_displaynum] {
	raise .biff_displaynum
	return
    }
    set tit "Message $num in [TKGDecode $f]"
    TKGDialog biff_displaynum -title $tit -wmtitle $tit \
	-text "Getting message . . ."
    set w .biff_displaynum.view.text
    set getcmd [join [list Biff $Biff($f,method) GetMessage] ""]
    if [Empty [info procs $getcmd]] {
	set getcmd {BiffScanHeaders msg}
    }
    set text [eval $getcmd $f $num]
 #    if [string match [lindex $text 0] error] {
 #	set text [lindex $text 1]
 #    }
    if ![winfo exists $w] return
    $w configure -state normal
    $w delete 1.0 end
    $w insert end $text
    $w configure -state disabled
}

proc BiffDoCount {f} {
    global Biff
    set file $Biff($f,folder)
    if [catch {lindex [exec cat $file | grep "^From " | wc -l] 0} n] {
	set n 0
    } 
    BiffCountLabel $f $n
}

proc BiffCountLabel {f n} {
    global Biff
    switch $n {
	"" {
	    set label ""
	} 1 {
	    set label "  1"
	} default {
	    set label [format "%3d" $n]
	}
    }
    if [winfo exists .biff3menu] {
	set text [format "%-[set Biff(maxnamelen)]s%3s" [TKGDecode $f] $label]
	.biff3menu entryconfigure \
	    [expr [lsearch $Biff(mailboxes) $f] + \
		 ($Biff(tearoff) && ! $Biff(usemenu))]\
	    -label $text
    } elseif !$Biff(nolabel) {
	upvar \#0 Biff-params P 
	set P(text,newmail) $label
    } else {
	set P(balloon,newmail) $label
    }
}

proc BiffCreateWindow {} {
    if [TKGReGrid Biff] return
    global Biff Biff-params Biff_strings TKG_labels TKG

    TKGClientStrings Biff

    if {[string first ~ $Biff(mailboxlist)] != -1 } {
	regsub -all ~ $Biff(mailboxes) [glob ~] Biff(mailboxlist)
    }
    foreach f $Biff(mailboxlist) {
	lappend Biff(mailboxes) [TKGEncode [lindex $f 1]]
    }

    # Create menu first, since we might be using it instead of button
    if {[llength $Biff(mailboxes)] > 1} {
	if {[Empty $Biff(menufont)]} {
	    set menufont tkgfixedmedium
	} else {
	    set menufont $Biff(menufont)
	}
	if {$Biff(usemenu)} {set type tearoff}
	menu .biff3menu -tearoff [expr $Biff(tearoff) && !$Biff(usemenu)]\
	    -background $TKG(buttonbackground)\
	    -activebackground $TKG(butactivebackground)\
	    -font $menufont
	set Biff(maxnamelen) 0
	foreach f $Biff(mailboxes) {
	    if {[string length $f] > $Biff(maxnamelen)} {
		set Biff(maxnamelen) [string length $f]
	    }
	}
	foreach f $Biff(mailboxes) {
	    .biff3menu add command \
		-label [format "%-[set Biff(maxnamelen)]s%3s" [TKGDecode $f] "  ?"]\
		-command "BiffDoFrm $f"
	}
	if $Biff(usemenu) {
	    .biff3menu post 400 400
	    set w [winfo reqwidth .biff3menu]
	    set h [winfo reqheight .biff3menu]
	    TKGMakeSwallow Biff -width $w -height $h\
		-exec "Tcl " -windowname biff3menu -borderwidth 0
	    bind .biff3menu <ButtonRelease-2> {
		BiffIgnoreFolder [lindex $Biff(mailboxes) [.biff3menu index active]]
		break
	    }
	    bind .biff3menu <ButtonRelease-3> {break}
	    bind .biff3menu <ButtonRelease-1> {
		if {![string match none [.biff3menu index active]]} {
		    .biff3menu invoke active
		}
		grab release .biff3menu
		break
	    }
	    return
	}
    }

    if {$Biff(noicon) && !$Biff(nolabel)} {
	set noicon ""
	set newicon ""
    } else {
	SetImage Biff_nomail_image $Biff(nomail_image)
	SetImage Biff_newmail_image $Biff(yellow,image)
	set noicon Biff_nomail_image
	set newicon Biff_newmail_image
    }
    if $Biff(nolabel) {
 	set notext ""
	set newtext ""
    } else {
	set notext $Biff_strings(nomail)
	set newtext $Biff_strings(newmail)
    }
    TKGMakeButton Biff \
        -text(nomail) $notext \
	-balloon(nomail) $notext \
	-image(nomail) $noicon\
        -exec(nomail) $Biff(mailer) \
	-foreground(nomail) $Biff(nomailforeground) \
	-activeforeground(nomail) $Biff(nomailforeground) \
	-background(nomail) $Biff(nomailbackground) \
        -text(newmail) $newtext \
        -balloon(newmail) $newtext \
	-image(newmail) $newicon\
        -exec(newmail) $Biff(mailer) \
	-foreground(newmail) $Biff(newmailforeground) \
	-activeforeground(newmail) $Biff(newmailforeground) \
	-background(newmail) $Biff(newmailbackground) \
	-iconside $Biff(iconside)\
	-relief $Biff(relief)\
	-ignore $Biff(ignore)\
	-font(nomail) $Biff(font)\
	-font(newmail) $Biff(font)\
	-usebutton2 0\
	-staydown(newmail) $Biff(staydown)\
	-staydown(nomail) $Biff(staydown)\
	-trackwindow(newmail) $Biff(trackwindow)\
	-trackwindow(nomail) $Biff(trackwindow)\
	-windowname(nomail) $Biff(windowname)\
	-windowname(newmail) $Biff(windowname)\
	-mode nomail
    bind [set Biff-params(pathname)] <2> BiffIgnore
    bind [set Biff-params(pathname)] <3> {Biff_3 %X %Y}
}

proc BiffMailboxDeclare {f} {
    global Biff Prefs_taborder
    set Prefs_taborder(:Clients,Biff,Mailboxes,[TKGDecode $f]) \
	"General Misc Method"
    TKGDeclare Biff($f,folder) "" \
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] General] \
	-label "Folder to check" \
	-help "Can be a full file or directory name, an MH mailbox (like \
+inbox), or an IMAP mailbox name (usually INBOX)."

    TKGDeclare Biff($f,update_interval) 60 \
        -typelist [list Clients Biff Mailboxes [TKGDecode $f] General] \
        -label "Check every __ seconds"

    TKGDeclare Biff($f,alertlevel) yellow\
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] General]\
	-vartype optionMenu \
        -optionlist {white green yellow red}\
        -label "Alert level" \
	-help "This affects the color of the new mail icon."

    TKGDeclare Biff($f,listall) 1\
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] Misc]\
	-vartype radio -radioside left\
        -label "Scan listing should list"\
        -radiolist {
            {"All messages" 1} 
            {"Unseen messages" 0}} \
        -help "This affects only MH and IMAP methods.  (With the other 
methods, there is no direct way to tell which messages are unseen.)"

    TKGDeclare Biff($f,frm) 0\
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] Misc]\
	-vartype boolean\
	-label "Post listing of new messages on arrival"

    TKGDeclare Biff($f,frm_command) ""\
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] Misc]\
	-label "Unix command to get (text) list of new mail (optional)."\
	-help "Leave blank to use tkgoodstuff's mail scanning code."

    TKGDeclare Biff($f,frm_instead) ""\
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] Misc]\
	-label "Unix command to execute instead of using tkgoodstuff's
lister."\
	-help "For instance, you might start your mailer."

    TKGDeclare Biff($f,newmailevent) ""\
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] Misc]\
	-label "Unix command executed when new mail is found."

    TKGDeclare Biff($f,nobeep) 0\
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] General]\
	-vartype boolean\
        -label "Don't beep"

    TKGDeclare Biff($f,method) ""\
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] Method]\
	-label "Mail Checking Method"\
        -help "Defaults to MH if folder is of the form '+name', and to 
the access/modification time method otherwise." \
	-vartype radio\
	-radiolist {
	    {"Check if Access/Modification times differ" atime}
	    {"Check if file is non-empty" filesize}
	    {"Scan messages for status flags" internal}
	    {"MH folder" MH}
	    {"Mailbox on IMAP server." IMAP}
	}
    BiffMailboxSpecialDeclare $f
    global TKGVars
    trace variable TKGVars(Biff($f,method),setting) w "BiffMailboxSpecialPrefs $f"
}

proc BiffMailboxSpecialDeclare {f args} {
    global Biff
    if [string match $Biff($f,method) IMAP] {
	BiffIMAPDeclare $f
    }
}

proc BiffMailboxSpecialPrefs {f args} {
    global TKGVars Biff
    if {[string match [set TKGVars(Biff($f,method),setting)] IMAP] 
	&& ![info exists Biff($f,host)]} {
	BiffIMAPDeclare $f
	PrefsUpdate
	set name [TKGDecode $f]
	TKGPrefs [list Clients Biff Mailboxes $name IMAP]\
	    "$name IMAP Preferences" .prefsClients~sBiff~sMailboxes~s$f
    }
}

proc BiffInit {} {
    global Biff
    set Biff(frm_selbg) white
    TKGAddToHook TKG_alldone_hook BiffGetGoing
}

proc BiffGetGoing {} {
    global Biff TKG env
    foreach f $Biff(mailboxes) {
	BiffMailboxDeclare $f
	if [Empty $Biff($f,folder)] {
	    if [string match $f INBOX] {
		if [info exists env(MAIL)] {
		    set Biff($f,folder) $env(MAIL)
		} else {
		    set dir /usr/spool/mail
		    foreach d {/usr/spool/mail /var/mail /var/spool/mail /usr/mail} {
			if [file isdirectory $d] {
			    set dir $d
			    break
			}
		    }
		    set Biff($f,folder) $dir/[exec whoami]
		}
	    } else {
		set Biff($f,folder) [TKGDecode $f]
	    }
	}
	# "+foldername" is MH
	if [Empty $Biff($f,method)] {
	    if [string match +* $Biff($f,folder)] {
		set Biff($f,method) MH
	    } else {
		set Biff($f,method) atime
	    }
	}
	set method $Biff($f,method)
	if [Empty [info procs Biff${method}Test]] {
	    Biff${method}Init
	}
	Biff${method}FolderInit $f
    }
    foreach f $Biff(mailboxes) {
	if ![Empty [info procs Biff${method}Start]] {
	    Biff${method}Start $f
	} else {
	    TKGPeriodic BiffUpdate$f \
		$Biff($f,update_interval) $Biff($f,update_interval) "BiffUpdate $f"
	    after 1000 BiffUpdate $f
	}
    }
}

DEBUG "Loaded Biff.tcl"
