#!/usr/bin/python

# generate utilization report
# # InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from pandas import *
import csv
import sys
from pylab import *
import os
from subprocess import call
from os.path import join as pjoin
import datetime
from htmltools import *


def utilDfFromFilename(filename):
    df = []
    with open(filename) as csvfile:
        rows = [a for a in csv.reader(csvfile, delimiter=' ') if a[3] == 'end']  
    for row in rows:
        rdata = [''] * 5
        if row[7] == 'clock':
            rdata = [x for x in reversed(row[8].split('/'))]
            rdata[0] = rdata[0].rstrip('_0123456789')
            rdata = rdata[0:5]
        else:
            rdata[4] = row[8]
        df.append(row[0:8] + rdata)

    d = DataFrame(df, columns='date time csecs rectype secs lpatid clinid app game gametype proto capp robot'.split())
    d.secs = d.secs.astype(float)
    # we are interested in every non-clock line and every adaptive line
    return d[(d.app != 'clock') | (d.game.str.contains('adaptive'))]


def hoursmins_fmt(secs):
    d = datetime.datetime(1, 1, 1) + datetime.timedelta(seconds=secs)
    return "{:02d}:{:02d}".format((d.day-1) * 24 + d.hour, d.minute)


def therapyPerGame(d):
    l = []
    for robot in sort(d.robot.unique()):
        for app in sort(d.app.unique()):
            count = len(d[(d.robot == robot) & (d.app == app)])
            if count:
                l.append([
                    robot,
                    app,
                    count,
                    hoursmins_fmt(d.secs[(d.robot == robot) & (d.app == app)].sum())
                ])

    html = comment('Therapy per Game') +\
           comment('NEED {}in'.format(1 + len(l) * 0.35)) +\
           tag('h3', 'Therapy per Game') +\
           '<table border=1 cellpadding=5>' +\
           thead('Robot', 'Game', 'Count', 'Time (H:M)')
    for (robot, app, count, hoursmins) in l:
        html += trow(robot, app, count, hoursmins)
    html += '</table>' + html_end()
    return html


def therapyPerDay(d):
    l = []
    for row in d[['date', 'secs']].groupby('date').aggregate([len, sum]).iterrows():
        l.append([row[0]] + list(row[1]))

    html = comment('Therapy per Day') +\
           tag('h3', 'Therapy per Day: {} days, Total Games {}, Total Time {}'.format(
               len(l),
               len(d),
               hoursmins_fmt(d.secs.sum())
           )) +\
           '<table border=1 cellpadding=5>'

    for i, row in enumerate(l):
        # row is date, count, seconds
        # handle multi-page tables with headers atop each page.
        # first page has a banner, so 18/page should be ok.
        if not i % 25:
            if i > 1:
                html += comment('NEW PAGE')
            html += thead('Day', 'Date', 'Count', 'Time (H:M)')
        html += trow(i + 1, row[0], int(row[1]), hoursmins_fmt(row[2]))

    html += '</table>' + imt_html_cpr_str() + comment('NEW PAGE')
    return html


def therapyGamesPerDay(d):
    l = []
    for row in d[['date', 'robot', 'app', 'clinid', 'secs']].groupby(
        ['date', 'robot', 'app', 'clinid']).aggregate([len, sum]).iterrows():
        l.append(list(row[0]) + list(row[1]))

    html = comment('Therapy Games per Day') +\
           tag('h3', 'Therapy Games per Day') +\
           '<table border=1 cellpadding=5>'

    for i, row in enumerate(l):
        # row is date, robot, app, clinician, count, seconds
        if not i % 25:
            if i > 1:
                html += comment('NEW PAGE')
            html += thead('Day', 'Date', 'Robot', 'Game', 'Clinican', 'Count', 'Time (H:M)')
        html += trow(i + 1, row[0], row[1], row[2], row[3], int(row[4]), hoursmins_fmt(row[5]))
    html += '</table><p>'
    return html


def header_footer(d):
    return comment('htmldoc settings') +\
           comment('MEDIA SIZE Universal') +\
           comment('HEADER LEFT ""') +\
           comment('HEADER CENTER ""') +\
           comment('HEADER RIGHT ""') +\
           comment('FOOTER LEFT "$DATE $TIME"') +\
           comment('FOOTER CENTER "Utilization for Patient {}"'.format(d.lpatid.unique()[0])) +\
           comment('FOOTER RIGHT "$PAGE/$PAGES"')


def banner(d):
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
    <h1>Utilization<br>Report</h1>
    </td>
    <!-- right -->
    <td valign="top">
    <b>Patient ID: {}</b><br>
    First Date: {}<br>
    Last Date: {}<br><br></td></tr></table>
    """.format(
        d.lpatid.unique()[0],
        d.date.min(),
        d.date.max()
    )


def utilHTML(patientdirectory):
    d = utilDfFromFilename(pjoin(patientdirectory, 'be.log'))
    return html_begin(d.lpatid.unique()[0]) +\
           header_footer(d) +\
           banner(d) +\
           therapyPerDay(d) +\
           therapyGamesPerDay(d) +\
           therapyPerGame(d) +\
           html_end()


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: utilreport.py <patientdirectory>")
        exit(1)
    utilhtml = utilHTML(pjoin(os.path.realpath(sys.argv[1])))
    fn = pjoin(os.path.realpath(sys.argv[1]), 'test_util')
    open(fn + '.html', 'w').write(utilhtml)
    call('/usr/bin/htmldoc --compression=9 --outfile ' + fn +
         '.pdf --quiet --bodyfont helvetica --textfont helvetica --webpage -t pdf ' + fn + '.html', shell=True)
