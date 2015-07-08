# TKGExpect --
# send a string and/or expect one among a list of strings
# - receive is a LIST of strings to expect
# - timeout after no input for timeout period.  There is no
# maximum 

proc TKGExpect {id send receive {timeout 30000}} {
    global TKGExpect
    foreach v {raw match submatch1 submatch2 error} {
	set TKGExpect($id,$v) ""
    }
    TKGExpectDebug "-----"
    if ![Empty $send] {
	TKGExpectDebug "Sending $send"
	if [catch {puts $id "$send"}] {
	    set TKGExpect($id,error) 1
	    return 0
	}
    }
    if {$receive == ""} {return 1}
    TKGExpectDebug "Waiting for $receive"
    TKGExpectDebug "RAW:"
    after $timeout set TKGExpect($id,success) 0
    fileevent $id readable [list TKGExpectRead $receive $id $timeout]
    set TKGExpect($id,success) 0
    vwait TKGExpect($id,success)
    fileevent $id readable {}
    after cancel set TKGExpect($id,success) 0
    TKGExpectDebug "Result is $TKGExpect($id,success)"
    TKGExpectDebug "-----"
    return $TKGExpect($id,success)
}

proc TKGExpectRead {strings id timeout} {
    global TKGExpect
    after cancel set TKGExpect($id,success) 0
    if [eof $id] {
	set TKGExpect($id,error) eof
	set TKGExpect($id,success) 0
	return
    }
    after $timeout set TKGExpect($id,success) 0
    if [catch {set new [read $id]}] {
	set TKGExpect($id,error) read
	set TKGExpect($id,success) 0
	return
    }
    append TKGExpect($id,raw) $new
    TKGExpectDebug $new 0
    foreach string $strings {
	if [regexp $string $TKGExpect($id,raw) \
		TKGExpect($id,match) \
		TKGExpect($id,submatch1) TKGExpect($id,submatch2)
	   ] {
	    set TKGExpect($id,success) 1
	}
    }    
}

proc TKGExpectDebug {s {newline 1}} {
 #    if $newline {
 #	puts $s
 #    } else {
 #	puts -nonewline $s
 #    }
 #    flush stdout
}

