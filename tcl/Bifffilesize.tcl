#"Filesize" method: assume a nonempty spool file has new mail, unless
#user has "ignored"; in that case wait for change of filesize.

proc BifffilesizeInit {} {
} 

proc BifffilesizeFolderInit {f} {
    global Biff
    set Biff($f,filesize) 0
}

proc BifffilesizeTest {f} {
    global Biff Biff-params
    set file $Biff($f,folder)
    if [catch {set filesize [file size $file]}] {
	set filesize 0
    }
    if {$filesize == $Biff($f,filesize)} {return nochange}
    if {$filesize == 0} {
	set Biff($f,filesize) 0
	return 0
    }
    set Biff($f,filesize) $filesize
    if $Biff(count) {
	BiffDoCount $f
    }
    return 1
}

proc BifffilesizeIgnore {f} {
    global Biff
    if [catch {set Biff($f,filesize) [file size $Biff($f,folder)]}] {
	set Biff($f,filesize) 0
    }
}

DEBUG "Loadded Bifffilesize.tcl"