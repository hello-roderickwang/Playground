source util.tcl
source menu.tcl

label .l -text name:
entry .e -textvariable env(IMT_PATIENT_NAME)

pack .l .e -side left
