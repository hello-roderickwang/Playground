Tue Jul 10 11:46:48 EDT 2012

fmt_adap - software to gather data from
clock/therapy/adaptive log files and compile the results
into a space-separated value file, suitable for use by a
spreadsheet.

The output columns are:

1 pm_version
2 patient_id
3 date
4 day
5 time
6 gamenum
7 slotnum

8 pm_init
9 pm_min_dist_along_axis
10 pm_robot_power
11 pm_jerkmag
12 pm_dist_straight_line

The five performance metrics data columns are 8-12.
Each row is the metrics collected during 80 slots of adaptive therapy.
Adaptive game generates 4 rows of data:

2 p123 20110901 Thu 133606 1 81 60 7 37 70 4
2 p123 20110901 Thu 133606 1 161 60 6 28 74 4
2 p123 20110901 Thu 133606 1 241 60 6 30 76 4
2 p123 20110901 Thu 133606 1 321 59 6 31 76 4

1) identifies the version of the metrics:
  0 - unidentified/incomplete/corrupt data
  1 - older metrics, based on a 100% scale with floating point values
  2 - newer metrics, based on a zero-is-best scale with integer values
2) Patient ID string
3) date in YYYYMMDD format
4) Day in Sun-Sat format
5) time in local 24 hour HHMMSS format
6) game number - Adaptive_1 would be 1.
7) slotnum - 81 is the metrics shown after 80 slots.

8-12) the five metrics shown in the colored display during adaptive therapy

The fmt_adap_1 program takes one adaptive metrics log file as input.
The name of the metrics file is of this form:

/home/imt/therapist/p123/therapy/20091123_Mon/adaptive_2_133545.asc

It converts this file into 4 rows (lines) of data, as above.
This data is written to standard output by fmt_adap_1, but it
is all redirected to a file by do_fmt_adap_all .

do_fmt_adap_all takes a folder name, usually
/home/imt/therapist, or the folder name of an individual
patient, like /home/imt/therapist/p123 .  It uses "find" to
find all the adaptive game log files in the folder, using
the glob pattern adaptive_*.asc .  do_fmt_adap_all gathers
the output from each call to fmt_adap_1, and writes all the
data to a file in the current folder called
fmt_adap_<date>_<time>.log for example,
fmt_adap_20120710_Tue_120237.log .  The name of this log
file is printed to stderr at the end of the run.

The do_fmt_adap_all software is designed to run on an entire therapist
folder full of patient data, and you may then take its one output file
and divide it up.

Notes on the internal operation of the software:

The slot numbers are 81, 161, 241, and 321, because the
metrics occur after the set of 80 slots has been completed
and the slot number has been incremented.

The input file is somewhat free-form, but most of the important data is
of the form <key> <space> <value>, so it's easy to parse.

Some of the data is compressed into filenames, for example, the
date and patient name are in the directory folder string.  These are
parsed out of string using split and lindex.

Sometimes data is missing (like if an adaptive therapy game
was stopped before the patient performed the full 320 slot
motions.  If so, the log file data might look like this:

0 None 20000000 Sun 000000 0 81 000 000 000 000 000

If only some data is missing, only some of these may be "empty,"
for example:

1 p123 20080123 Wed 161249 1 161 000 000 000 000 000

In the performance metrics columns, 000 indicates that data
is missing, because a normal zero will show as 0.  000 does
not indicate that the whole file is corrupt, for example, if
a patient performed 250 slots before stopping, the file may
show three good rows and one row of 000s.

The versions indicated in the first column represent two
different data formats.  There is no simple mapping between
version 1 and 2 data.  When the version is 0, that means the
software had trouble reading the file - it is safest to
ignore the data that follows in that row, or at least
inspect the source log files manually to determine the
problem.  The fmt_adap software uses:

presence of the pm_active_power metric for slot 81 to indicate version 1
presence of the pm_robot_power metric for slot 81 to indicate version 2
presence of the neither of these to indicate version 0

The version determination is on a per-file basis, so a single run
of do_fmt_adap_all can generate a log file that is a combination
of data generated from different versions of the adaptive software,
some version 1 and some version 2.

The software attempts to be robust when presented with corrupt or
incomplete data.  It might print these messages to stderr:

Warning, missing folder name data.
Warning, missing game name data.
Warning, file is both version 1 and 2.
Warning, missing metric data.

fmt_adap_1 prints the name of the file it is processing to
stderr.  If warnings are printed, they will refer to the
file name that precedes the warning.  Warnings are not unusual,
particularly, "missing metric data" will occur whenever an adaptive
session was stopped before it was completed.

TODO and ideas:

a tool to convert a single patient's data into a PDF table,
a la the pups reports

a warning summary, instead of just printing warnings
