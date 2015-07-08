# method for MH folders
# Written by Gary Dezern (gdezern@uniquecr.sundial.net)
# and M. Crimmins.

# array BiffMH():
#  mh_path - path to MH binaries
#  path - path to MH folders (usually just "Mail")
#  seq - name of the unseen-sequence. (usually "unseen")
#  scan - command line for calling 'scan'
#  rcvstore - preferences switch.  1 if MH's rcvstore is used
#    to incorporate new mail into folders (in that case, we
#    look at unseen-sequence; otherwise look at atimes/mtimes).

proc BiffMHInit {} {
    global BiffMH env

    if [Empty $BiffMH(mh_path)] {
	foreach dir [split $env(PATH) :] {
	    lappend mhpath "${dir}/mh$"
	}
	foreach dir \
	    [concat [split $env(PATH) :] $mhpath /usr/local/bin/mh] {
	    if [file exists $dir/mhparam] {
		set BiffMH(mh_path) $dir
	    }
	    }
    }
    if ![file exists $BiffMH(mh_path)/mhparam] {
	TKGNotice "Biff: Cannot find directory of MH binaries.
Set it by hand in the preferences manager."
	return
    }
    set env(PATH) [set BiffMH(mh_path)]:$env(PATH)
    set BiffMH(path) Mail
    set BiffMH(scan) scan
    if [string length $BiffMH(scan_params)] {
        lappend BiffMH(scan) $BiffMH(scan_params)
    }
    
    if !$BiffMH(rcvstore) return
    
    if [catch "exec mhparam unseen-sequence" BiffMH(seq)] {
        TKGError "Biff: Unable to locate MH unseen-sequence.
Please verify your MH setup: in your ~/.mh-profile you 
should have a line like \"Unseen-Sequence: u\"."
    }
    
    if [catch "exec mhparam mh-sequences" BiffMH(mhseq)] {
        set BiffMH(mhseq) ".mh_sequences"
    }
}

proc BiffMHFolderInit {f} {
    global BiffMH Biff
    set folder $Biff($f,folder)
    set Biff($f,mtime) 0
    set Biff($f,oldmtime) 0
    if [string match [string index $folder 0] +] {
	if [catch "exec mhpath $folder" fpath] {
	    TKGError "Unable to locate path to $folder: $fpath"
	    return
	}
    } else {
	set fpath $folder
    }
    set Biff($f,path) "$fpath"
    if $BiffMH(rcvstore) {
	global BiffMH(mhseq)
	set Biff($f,seqpath) "$fpath/$BiffMH(mhseq)"
    }
}

proc BiffMHTest {f} {
    global Biff Biff-params BiffMH
    set folder $Biff($f,folder)
    if $BiffMH(rcvstore) {
	set testfile $Biff($f,seqpath)
    } else {
	set testfile $Biff($f,path)
    }
    if ![file exists $testfile] {
	if $Biff(count) {
	    BiffCountLabel $f 0
	}
	return 0
    }
    set t [file mtime $testfile]

    if {$t > $Biff($f,mtime)} {
	set Biff($f,oldmtime) $Biff($f,mtime)
	set Biff($f,mtime) $t
	if $BiffMH(rcvstore) {
	    return [BiffMHseqcheck $f]
	} else {
	    return [BiffMHatimecheck $f]
	}
    } else {
	return nochange
    }
}

proc BiffMHIgnore {f} {
    global Biff
    set dir $Biff($f,path)
    if [file exists $dir] {
	    set Biff(f,mtime) [file mtime $dir]
    }
}

proc BiffMHatimecheck {f {getlist 0}} {
    global Biff BiffMH
    set dir $Biff($f,path)
    set Biff($f,unseen) ""
    foreach file [glob -nocomplain $dir/*] {
    	if {[catch {expr [file tail $file]}] || [file isdirectory $file]} continue
	file stat $file a
	if {$a(atime) <= $a(mtime)} {
	    if {!$Biff(count) && !$getlist} {return 1}
	    lappend Biff($f,unseen) [file tail $file]
	} 
    }
    set n [llength $Biff($f,unseen)]
    if $Biff(count) {
	BiffCountLabel $f $n
    }
    return [expr $n > 0]
}

proc BiffMHseqcheck {f} {
    global BiffMH Biff
    set Biff($f,unseen) ""
    if ![file exists $Biff($f,seqpath)] {return 0}
    if [catch {open $Biff($f,seqpath)} inf] {
	return 0
    }
    fconfigure $inf -blocking 0
    while {![eof $inf]} {
	gets $inf line
	if [string match $BiffMH(seq):* $line]  {
	    if { [llength $line] > 1 } {
		set Biff($f,unseen) "[lrange $line 1 end]"
	    }
	}
    }
    close $inf
    set unseen [BiffMHSeqTrans $Biff($f,unseen)]
    set n [llength $unseen]
    if $Biff(count) {
	BiffCountLabel $f $n
    }
    set new 0
    foreach msg $unseen {
	if {[file mtime $Biff($f,path)/$msg] > $Biff($f,oldmtime)} {
	    set new 1
	    break
	}
    }
    return $new
}

proc BiffMHScan {f} {
    global BiffMH Biff
    set dir $Biff($f,path)
    if $BiffMH(rcvstore) {
	BiffMHseqcheck $f
    } else {
	BiffMHatimecheck $f 1
	exec touch -m $dir
    }
    set unseen [lsort -integer [BiffMHSeqTrans $Biff($f,unseen)]]
    if $Biff($f,listall) {
	set pwd [pwd]
	cd $Biff($f,path)
	set msglist [lsort -integer [glob -nocomplain \[0-9\]*]]
	cd $pwd
    } else {
	set msglist $unseen
    }
    foreach mnum $msglist {
	set id [open $dir/$mnum]
	set from($mnum) ""
	set subject($mnum) ""
	set new($mnum) [In $mnum $unseen]
	while {[gets $id l] != -1} {
	    switch -glob -- $l {
		"From*" {
		    regexp "^From: *(.*)" "$l" v from($mnum)
		} "Subject: *" {
		    regexp "^Subject: *(.*)" "$l" v subject($mnum)
		} "" { break }
	    }
	}
	close $id
    }
    set frmlist ""
    foreach i $msglist {
	lappend frmlist [list $from($i) $subject($i) $new($i) $i]
    }
    return $frmlist
}

proc BiffMHGetMessage {f mnum} {
    global BiffMH Biff
    catch {exec $BiffMH(mh_path)/show $Biff($f,folder) $mnum -noshowproc} out
    return $out
}

proc BiffMHSeqTrans {seq} {
    set ret ""
    foreach item $seq {
	if {[llength [set s [split $item -]]] == 1} {
	    lappend ret $item
	} else {
	    for {set i [lindex $s 0]} {$i <= [lindex $s 1]} {incr i} {
		lappend ret $i
	    }
	}
    }
    return $ret
}
    
proc BiffMHExmh {f} {
    global Biff Fvwm
    if {[In exmh [winfo interps]]} {
	set box [string trimleft $Biff($f,folder) +]
	if {[string match inbox $box] || [string match INBOX $f]} {
	    send exmh "Inc"
	    send exmh "Folder_Change inbox"
	} else {
	    send exmh "Folder_Change $box"
	}
	send exmh "Msg_ShowUnseen"
	if {[info exists Fvwm(outid)]} {
	    FvwmNext exmh
	} else {
	    send exmh "wm deiconify .; raise ."
	}
    } else {
	exec exmh &
    }
}

DEBUG "Loaded BiffMH.tcl"   

