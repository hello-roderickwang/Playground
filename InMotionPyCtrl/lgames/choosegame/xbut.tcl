# http://mini.net/cgi-bin/wikit/639.html

# call:
# xbutton .foo -text xx ?-font xx? ?-bitmap xx? ?-image xx? \
#  ?-side xx? ?-background xx? ?-activebackground xx? -command xx \
#  ?-expand xx? ?-relief xx*? ?-borderwidth xx*?

proc xbutton {w args} {
   button $w                  ;# only for getting defaults
   foreach i {-background -activebackground -font} {
       set a($i) [$w cget $i]
   }
   destroy $w
   array set a [concat {
       -side top -relief raised -borderwidth 2 -command {} -expand 1
   } $args]
   frame $w -relief $a(-relief) -borderwidth $a(-borderwidth)
   if [info exists a(-image)] {
       label $w.b -image $a(-image) -bg $a(-background)
   } elseif [info exists a(-bitmap)] {
       label $w.b -bitmap $a(-bitmap) -bg $a(-background)
   }
   if [info exists a(-text)] {
       label $w.t -text $a(-text) -font $a(-font) -bg $a(-background)
   }
   eval pack [winfo children $w] -side $a(-side) -fill both \
           -expand $a(-expand)
   xbind $w <Enter> "xconfigure %W -bg $a(-activebackground);
   $w configure -relief raised; update"
   xbind $w <Leave> "xconfigure %W -bg $a(-background);
   $w configure -relief $a(-relief); update"
   xbind $w <ButtonPress-1> \
           "$w configure -relief sunken; update; eval [list $a(-command)]"
   xbind $w <ButtonRelease-1> "$w configure -relief raised"
}
proc xbind {w event body} {
   if ![llength [winfo children $w]] {set w [winfo parent $w]}
   foreach i [concat $w [winfo children $w]] {
       bind $i $event $body
   }
} ;# binds to children and parent
proc xconfigure {w args} {
   if ![llength [winfo children $w]] {set w [winfo parent $w]}
   foreach i [concat $w [winfo children $w]] {
       eval $i configure $args
   }
}
