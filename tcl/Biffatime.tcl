#Biff "atime" method: assume there's new mail if the file is nonempty and
#hasn't been accessed since last modification.

proc BiffatimeInit {} {
} 

proc BiffatimeFolderInit {f} {
    global Biff
    set Biff($f,mtime) 0
    set Biff($f,atime) 0
}

proc BiffatimeTest {f} {
    global Biff Biff-params
    set file $Biff($f,folder)
    if [catch {file stat $file a}] {
	return 0
    } elseif {($a(mtime) == $Biff($f,mtime)) && \
		  ($a(atime) == $Biff($f,atime))} {
	return nochange
    }
    set Biff($f,mtime) $a(mtime)
    set Biff($f,atime) $a(atime)
    if {(( $a(size) == 0) || ($a(mtime) < $a(atime)))} {
	set return 0
    } else {
	set return 1
    } 
    if $Biff(count) {
	BiffDoCount $f
	file stat $file a
	set Biff($f,atime) $a(atime)
	set Biff($f,mtime) $a(mtime)
    }
    return $return
}

proc BiffatimeIgnore {f} {
    global Biff
    set file $Biff($f,folder)
    if [catch {file stat $file a}] return
    set Biff($f,mtime) $a(mtime)
    set Biff($f,atime) $a(atime)
}

DEBUG "Loaded Biffatime.tcl"