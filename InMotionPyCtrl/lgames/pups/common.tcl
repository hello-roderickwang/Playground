# common procs for performance and utilization reports
proc is_lkm_loaded {} {
    expr {![catch {exec pgrep -x robot}]}
}

