#"Internal" method: scan headers for "Status:" flags on any
#modification of the spool file.

proc BiffinternalInit {} {
} 

proc BiffinternalFolderInit {f} {
    global Biff
    set Biff($f,mtime) 0
}

proc BiffinternalTest {f} {
    global Biff Biff-params
    set file $Biff($f,folder)
    if [catch {file stat $file a}] {
	set return 0
    } elseif {$a(mtime) <= $Biff($f,mtime)} {
	return nochange
    } else {
	set Biff($f,mtime) $a(mtime)
	set return [BiffScanHeaders check $f]
    }
    if $Biff(count) {BiffDoCount $f}
    return $return
}

proc BiffinternalIgnore {f} {
    global Biff
    if [catch {file stat $Biff($f,folder) a}] return
    set Biff($f,mtime) $a(mtime)
}

DEBUG "Loadded Biffinternal.tcl"