#!/usr/bin/python

# generate log data report
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

import os
from htmltools import *


def checkSessions(eval_day):
    good_count = {
        'point_to_point2d': 80,
        'point_to_pointps': 20,
        'circle': 20,
        'playback_static2d': 1,
        'playback_staticps': 1,
        'round_dynamic2d': 16,
        'round_dynamicps': 4,
        'shoulder': 20
    }
    html = '<table border=1 cellpadding=5>' +\
           thead('Type', 'Count', 'Count should be')
    for t in eval_day:
        if eval_day[t] == good_count[t]:
            good_count[t] = '&nbsp;'
        html += trow(t.replace('_', ' '), eval_day[t], good_count[t])
    html += '</table>'
    return html


def header_footer(patid):
    return comment('htmldoc settings') +\
           comment('MEDIA SIZE Universal') +\
           comment('HEADER LEFT ""') +\
           comment('HEADER CENTER ""') +\
           comment('HEADER RIGHT ""') +\
           comment('FOOTER LEFT "$DATE $TIME"') +\
           comment('FOOTER CENTER "Log Data for Patient {}"'.format(patid)) +\
           comment('FOOTER RIGHT "$PAGE/$PAGES"')


def banner(patid, sessions):
    logo = '<img src="' + os.path.dirname(os.path.abspath(__file__)) + '/inmo.gif" width=215 height=50>'
    return comment('banner') + """
    <table width=680>
    <tr>
    <!-- left -->
    <td valign="top">
    """ + logo + """
    </td>
    <!-- center -->
    <td valign="top">
    <h1>Log Data<br>Report</h1>
    </td>
    <!-- right -->
    <td valign="top">
    <b>Patient ID: {}</b><br>
    Sessions: {}<br>
    </td></tr></table><hr>
    """.format(patid, sessions)


def checkHTML(patid, check):
    html = html_begin('Log Data Report for '.format(patid)) +\
           header_footer(patid) +\
           banner(patid, len(check))
    for eval_num, eval_day in enumerate(sorted(check)):
        if eval_num % 3 == 0 and eval_num > 0:
            html += comment('NEW PAGE')
        html += '<table border=0 cellpadding=10>' +\
                thead('Evaluation: {}</table>'.format(eval_day))
        html += checkSessions(check[eval_day])
    html += html_end()
    return html


