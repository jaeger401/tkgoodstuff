# Ical-fetch.tcl for tkgoodstuff

calendar maincal $env(HOME)/.calendar 

set today [date today]

set default_alarms { 0 5 10 15 }
catch { eval "set default_alarms \{ [maincal option DefaultAlarms ]\}"}

maincal query $today $today item date {
  if [$item is appt] {
      set ialarmlist [expr [catch {$item alarms} outtext ] == 0 ? {$outtext} : [list $default_alarms] ]
      set alarmlist ""
      for {set i 0} {$i < [llength $ialarmlist]} {incr i} {
	  if {[lsearch $alarmlist [lindex $ialarmlist $i]] == -1} {
	      lappend alarmlist [lindex $ialarmlist $i]
	  }
      }
      puts "lappend Ical(itemlist) \[list [$item starttime] [list $alarmlist] [list [$item text]] \]"
    }
}

exit
