proc BiffScanHeaders {action f {getnum ""}} {
    global Biff
    set file $Biff($f,folder)
    set frm [string match $action frm]
    set chk [string match $action check]
    set msg [string match $action msg]
    set msgtext ""
    set id [open $file]
    set new(0) 0
    set mnum 0
    set inheader 0
    while {![eof $id]} {
	set l [gets $id]
	if [string match "From *" $l] {
	    if {$chk && ($mnum != 0) && $new($mnum)} break
	    incr mnum
	    set inheader 1
	    set new($mnum) 1
	    if {$frm} {
		set from($mnum) ""
		set subject($mnum) ""
		set date($mnum) ""
		set to($mnum) ""
		set cc($mnum) ""
	    }
	    continue
	} elseif $inheader {
	    switch -glob -- $l {
		"Status:*" {
		    regexp "Status: *(.*)" $l v v
		    if {$v != "N"} {set new($mnum) 0}
		} "Subject:*" {
		    if {$frm} {
			regexp "Subject: *(.*)" $l v subject($mnum)
		    }
		} "From:*" {
		    if {$frm} {
			regexp "From: *(.*)" $l v from($mnum)
		    }
		} "Date:*" {
		    if {$frm} {
			regexp "Date: *(.*)" $l v date($mnum)
		    }
		} "To:*" {
		    if {$frm} {
			regexp "To: *(.*)" $l v to($mnum)
		    }
		} "cc:*" {
		    if {$frm} {
			regexp "cc: *(.*)" $l v cc($mnum)
		    }
		} "" {
		    set inheader 0
		}
	    }
	} 
	if {$msg && ($mnum == $getnum)} {append msgtext "$l\n"}
    }
    close $id
    if $chk {return $new($mnum)}
    if $frm {
	set frmlist ""
	for {set i 1} {$i <= $mnum} {incr i} {
	    lappend frmlist [list $from($i) $subject($i) $new($i) $i $date($i)]
	}
	return $frmlist
    } elseif $msg {
	return $msgtext
    }
}	
