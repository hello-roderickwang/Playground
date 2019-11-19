# @Date    : 2019-11-18 16:23:21
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

global ob

set ob(crobhome) $::env(CROB_HOME)

source $ob(crobhome)/shm.tcl

#start_lkm
start_shm
start_loop
after 100

wshm no_safety_check 1
wshm stiff 100
wshm damp 5
wshm slot_max 4

set direction "null"
set speed 0
set start_x 0
set start_y 0
set end_x 0
set end_y 0
# ticks controls the loop of movebox
# the robot main loop runs 200Hz
# if you want this movebox command refresh every 5 seconds, set it to 200*5=1000
set ticks 1000

if {$argc != 6} {
    puts "The movebox.tcl script requires 6 arguments."
    puts "Arguments are:"
    puts "    direction(up/down/left/right)"
    puts "    speed(float)"
    puts "    start_x(float)"
    puts "    start_y(float)"
    puts "    end_x(float)"
    puts "    end_y(float)"
} else {
    set direction [lindex $argv 0]
    set speed [lindex $argv 1]
    set start_x [lindex $argv 2]
    set start_y [lindex $argv 3]
    set end_x [lindex $argv 4]
    set end_y [lindex $argv 5]
}

puts $direction
puts $speed
puts $start_x
puts $start_y
puts $end_x
puts $end_y

movebox 0 0 {0 $ticks 1} {$start_x $start_y 0 0} {$end_x $end_y 0 0}

# after 5000
