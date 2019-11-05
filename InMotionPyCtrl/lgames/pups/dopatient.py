#!/usr/bin/python

# create report for a patient
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from utils import *
import sys
import os
import argparse
from os.path import join as pjoin
from subprocess import check_output, CalledProcessError
from glob import glob
from shutil import copyfile
import datetime
from collections import defaultdict
from string import Template
import ellipse
import playbackstatic
import pointToPoint
import roundDynamic
import shoulder
from utilreport import utilHTML
from countreport import checkHTML
import yaml

PUPS_HOME = os.path.dirname(os.path.abspath(__file__))
try:
    THERAPIST_HOME = os.environ['THERAPIST_HOME']
except KeyError:
    print('The THERAPIST_HOME environment variable is not set. Exiting.')
    exit(1)


def reportHTML(t=None, patid=0, evaluation='', reportfolder='',
               xofy='', first='', last='', template='planar'):
    if not t:
        t = {}

    ob = defaultdict(str)
    ob['patid'] = patid
    ob['first'] = dateify(first)
    ob['last'] = dateify(last)
    ob['dateprefix'] = evaluation
    ob['date'] = dateify(evaluation)
    ob['year'] = datetime.datetime.now().year
    ob['xofy'] = xofy
    ob['patrepdir'] = reportfolder
    ob['PUPS_HOME'] = PUPS_HOME
    for p in t:
        for w in t[p]:
            ob[(p + '_' + w).replace(' ', '_')] = t[p][w]
    return Template(open(pjoin(PUPS_HOME, template)).read()).safe_substitute(ob)


def coverHTML(patid=0, tableOfContents=None):
    ob = defaultdict(str)
    ob['PUPS_HOME'] = PUPS_HOME
    ob['tableofcontentshtml'] = '<br>'.join([tableOfContents[k] for k in sorted(tableOfContents.iterkeys())])
    ob['patid'] = patid
    return Template(open(pjoin(PUPS_HOME, 'tpl/cover')).read()).safe_substitute(ob)


def noteHTML(patid=0, note=''):
    ob = defaultdict(str)
    ob['patid'] = patid
    ob['year'] = datetime.datetime.now().year
    ob['note'] = note
    ob['PUPS_HOME'] = PUPS_HOME
    return Template(open(pjoin(PUPS_HOME, 'tpl/note')).read()).safe_substitute(ob)


def reportCSV(t=None):
    if not t:
        t = {}
    ret = ''
    for ev in t:
        for p in t[ev]:
            for w in t[ev][p]:
                try:
                    ret += ','.join((ev, p, w, t[ev][p][w])) + '\n'
                except (TypeError, AssertionError):
                    ret += ','.join((ev, p, w, 'Data Missing')) + '\n'
    return ret


def dopatient(patid, nocache):
    def print_task():
        print(xofy + ' ' + gametask)

    def print_missing(*args):
        print('Data missing for ' + ' '.join([str(x) for x in args]))

    if is_robot_running():
        print('Robot is running, please stop it before running reports.')
        exit(1)
    inpath_patient = pjoin(THERAPIST_HOME, patid)

    if (os.path.exists(pjoin(inpath_patient, 'is_10cm'))
        or os.path.exists(pjoin(inpath_patient, 'is_pediatric'))):
        pathlen_from_is_file = 0.1
    else:
        pathlen_from_is_file = 0.14

    inpath_patient_evals = pjoin(inpath_patient, 'eval')
    inpath_patient_therapys = pjoin(inpath_patient, 'therapy')
    outpath_reports = pjoin(os.environ['HOME'], 'reports', 'pdfs')
    outpath_extras = pjoin(os.environ['HOME'], 'reports', 'raw_data', patid)
    gametask = ''
    robot = 'planar'  # by default, until we learn otherwise

    mkdir_p(outpath_reports)
    mkdir_p(outpath_extras)
    
    # give them the help filename
    docrobot = 'arm'  # by default
    if robot == 'wrist':
        docrobot = 'wrist'

    copyfile(pjoin(PUPS_HOME, '..', '..', 'man', 'report-help-{}.html'.format(docrobot)),
             pjoin(outpath_reports, '00report-help.html'))

    t = rhash()
    check = rhash()
    tableOfContents = {}

    # find all the folders
    eval_days = [os.path.basename(x) for x in sorted(glob(pjoin(inpath_patient_evals, '2???????_???')))]
    therapy_days = [os.path.basename(x) for x in sorted(glob(pjoin(inpath_patient_therapys, '2???????_???')))]

    if not eval_days:
        print('Critical: No eval folders found.')
        exit(1)

    if not therapy_days:
        print('Warning: No therapy folders found.')

    if bool(glob(pjoin(inpath_patient_evals, eval_days[0], 'wr_*'))):
        robot = 'wrist'
        print('This is a wrist patient.')

    print('Writing daily therapy one way records.')

    for proc_num, proc_day in enumerate(therapy_days):
        xofy = '{} / {}'.format(proc_num + 1, len(therapy_days))
        inpath_patient_therapy_day = pjoin(inpath_patient_therapys, proc_day)

        def rf():
            return pjoin(outpath_extras, proc_day + '_' + str(run + 1) + '_' + gametask)

        gametask = 'oneway_rec'
        for run in range(4):
            if run == 0:
                print_task()
            try:
                (data, all_x, all_y, all_z) = pointToPoint.ptpmulti(inpath_patient_therapy_day, run=run + 1,
                                                                    robot=robot, pathlen_from_is_file=pathlen_from_is_file,
                                                                    num=16)
                write_plot(all_x, all_y, rf(), robot=robot, nocache=nocache, pathlength=data['pathlength'])
                for w in ('smoothness', 'reach_error', 'mean_vel', 'max_vel', 'path_error', 'initiation_time'):
                    t[proc_day][gametask]['{}_{}'.format(w, run + 1)] = fmt(data[w])
            except (TypeError, AssertionError, AttributeError):
                write_no_data_plot(rf())
                print_missing(proc_day, run, gametask)

        # generate PDFs and HTMLs for this evaluation day
        template = 'tpl/{}-owr'.format(robot)
        htmltext = reportHTML(t=t[proc_day], template=template, patid=patid, evaluation=proc_day, xofy=xofy)
        filename = '{}_therapy_{}'.format(patid, proc_day)
        write_pdf(pjoin(outpath_extras, filename), pjoin(outpath_reports, filename), htmltext)

        # add to TOC
        tableOfContents[filename] = 'Daily Therapy Report, {}'.format(dateify(proc_day))

    dimensions = ['2d']
    if robot == 'wrist':
        dimensions.append('ps')

    for proc_num, proc_day in enumerate(eval_days):
        print('Writing evaluation data.')
        xofy = '{} / {}'.format(proc_num + 1, len(eval_days))
        inpath_patient_eval_day = pjoin(inpath_patient_evals, proc_day)

        def rf():
            return pjoin(outpath_extras, proc_day + '_' + gametask)

        for dimension in dimensions:
            try:
                gametask = 'point_to_point' + dimension
                print_task()
                (data, all_x, all_y, all_z) = pointToPoint.ptpmulti(inpath_patient_eval_day,
                                                                    robot=robot,
                                                                    pathlen_from_is_file=pathlen_from_is_file,
                                                                    dimension=dimension,
                                                                    num=80 if dimension == '2d' else 20)

                if dimension == '2d':
                    write_plot(all_x, all_y, rf(), robot=robot, nocache=nocache, pathlength=data['pathlength'])
                else:
                    write_plot_ps(data, rf(), nocache=nocache)
                for w in ('smoothness', 'reach_error', 'mean_vel', 'max_vel', 'path_error', 'initiation_time'):
                    t[proc_day][gametask][w] = fmt(data[w])
                check[proc_day][gametask] = len(all_x)
            except (TypeError, AssertionError, AttributeError):
                check[proc_day][gametask] = 0
                write_no_data_plot(rf())
                print_missing(proc_day, gametask)

            try:
                gametask = 'playback_static' + dimension
                print_task()
                (data, d) = playbackstatic.pbs1(inpath_patient_eval_day, robot=robot, dimension=dimension)
                if dimension == '2d':
                    write_plot([d.x], [d.y], rf(), robot=robot, nocache=nocache, pathlength=data['pathlength'])
                else:
                    write_plot_ps({'E': {1: abs(max(d.z))}, 'W': {1: abs(min(d.z))}}, rf(), nocache=nocache)
                    #writePlot([d.z], [(d.i - min(d.i)) / Hz], rf(), robot=robot, nocache=nocache, plottype='ps')
                t[proc_day][gametask]['hold_deviation'] = fmt(data['hold_deviation'])
                if dimension == '2d':
                    for i, direction in enumerate(north_cw_rose):
                        try:
                            t[proc_day][gametask][direction] = fmt(data['maxdir'][i])
                        except IndexError:
                            print('Data missing for {} {} {}'.format(proc_day, gametask, direction))
                else:
                    t[proc_day][gametask]['L'] = fmt(abs(min(d.z)))
                    t[proc_day][gametask]['R'] = fmt(abs(max(d.z)))
                check[proc_day][gametask] = 1
            except (TypeError, AssertionError, AttributeError):
                check[proc_day][gametask] = 0
                write_no_data_plot(rf())
                print_missing(proc_day, gametask)

            try:
                gametask = 'round_dynamic' + dimension
                print_task()
                (data, all_x, all_y, all_z) = roundDynamic.rd8(inpath_patient_eval_day,
                                                               robot=robot,
                                                               dimension=dimension)
                t[proc_day][gametask]['displacement'] = fmt(data['displacement'])
                if dimension == '2d':
                    ROSE = north_cw_rose
                    write_plot(all_x, all_y, rf(), robot=robot, nocache=nocache, pathlength=data['pathlength'])
                else:
                    ROSE = ['E', 'W']
                    write_plot_ps(data, rf(), nocache=nocache)
                    t[proc_day][gametask]['L'] = fmt(abs(min(all_z[1])))
                    t[proc_day][gametask]['R'] = fmt(abs(max(all_z[0])))
                for i, direction in enumerate(ROSE):
                    try:
                        t[proc_day][gametask][direction] = fmt(data['disp'][direction])
                    except KeyError:
                        print('Data missing for {} {} {}'.format(proc_day, gametask, direction))
                check[proc_day][gametask] = len(all_x) * 2
            except (TypeError, AssertionError, AttributeError):
                check[proc_day][gametask] = 0
                write_no_data_plot(rf())
                print_missing(proc_day, gametask)

        if robot == 'planar':
            try:
                gametask = 'circle'
                print_task()
                (data, all_x, all_y) = ellipse.ell20(inpath_patient_eval_day)
                write_plot(all_x, all_y, rf(), robot=robot, nocache=nocache, noTargets=True)
                for w in ('circle_size', 'independence'):
                    t[proc_day][gametask][w] = fmt(data[w])
                check[proc_day][gametask] = len(all_x)
            except (TypeError, AssertionError, AttributeError):
                check[proc_day][gametask] = 0
                write_no_data_plot(rf())
                print_missing(proc_day, gametask)

            check[proc_day]['shoulder'] = 0
            for s in shoulder.SHOULDERTYPES:
                try:
                    gametask = 'shoulder_' + s
                    print_task()
                    (data, all_x, all_y) = shoulder.sh5(inpath_patient_eval_day, s)
                    write_plot(all_x, all_y, rf(), plottype='shoulder', nocache=nocache)
                    t[proc_day][gametask]['max_change_in_force'] = '{0:2.1f}'.format(data['max_change_in_force'])
                    check[proc_day]['shoulder'] += len(all_x)
                except (TypeError, AssertionError, AttributeError):
                    write_no_data_plot(rf())
                    print_missing(proc_day, gametask)

        # generate PDFs and HTMLs for this evaluation day
        print(xofy + ' evaluation report')

        templates = {'wrist': {'tpl/wrist-2d': '2d', 'tpl/wrist-ps': 'ps'},
                     'planar': {'tpl/planar': '2d'}}

        for template in templates[robot]:
            htmltext = reportHTML(t=t[proc_day], template=template, patid=patid, evaluation=proc_day, xofy=xofy)
            filename = '{}_eval_{}_{}'.format(patid, templates[robot][template], proc_day)
            write_pdf(pjoin(outpath_extras, filename), pjoin(outpath_reports, filename), htmltext)
            tableOfContents[filename] = 'Evaluation Report {}, {}'.format(templates[robot][template], dateify(proc_day))

    # now generate the progress report barcharts, using the first and last evals
    # this hash (populated from yaml config file) tells us what to plot and also what the ylimits are

    plotlimits = yaml.load(open(pjoin(PUPS_HOME, 'config/barcharts')))

    for gametask in plotlimits[robot]:
        for w in plotlimits[robot][gametask]:
            ynorm = plotlimits[robot][gametask][w]['norm']
            ylimit = plotlimits[robot][gametask][w]['limit']
            try:
                data = [float(t[proc_day][gametask][w]) for proc_day in eval_days]
                write_progress_plot(data, ynorm, ylimit, pjoin(outpath_extras, 'prog_' + gametask + '_' + w))
            except TypeError:
                write_no_data_plot(pjoin(outpath_extras, 'prog_' + gametask + '_' + w))

    # generate PDFs and HTMLs for the progress report
    for dimension in dimensions:
        print('Generating progress report {}'.format(dimension))
        htmltext = reportHTML(patid=patid, first=min(eval_days), last=max(eval_days),
                              reportfolder=outpath_reports,
                              template='tpl/prog-{}-{}'.format(robot, dimension))
        filename = '{}_prog_{}'.format(patid, dimension)
        write_pdf(pjoin(outpath_extras, filename), pjoin(outpath_reports, filename), htmltext)
        tableOfContents[filename] = 'Progress Report {}, {} to {}'.format(dimension, dateify(min(eval_days)),
                                                                          dateify(max(eval_days)))

    # generate the utilization report
    try:
        print('Generating utilization report')
        htmltext = utilHTML(inpath_patient)
        filename = '{}_util'.format(patid)
        write_pdf(pjoin(outpath_extras, filename), pjoin(outpath_reports, filename), htmltext)
        tableOfContents[filename] = 'Utilization Report, {} to {}'.format(dateify(min(therapy_days)),
                                                                          dateify(max(therapy_days)))
    except IOError:
        print('No be.log found so no utilization report created.')
    except IndexError:
        print('No adaptive games found so no utilization report created.')
    except ValueError:
        print('No therapy days found so no utilization report created.')

    # generate the notes
    try:
        notes = '<br>'.join(open(pjoin(inpath_patient, 'note')).readlines())
        print('Generating notes')
        htmltext = noteHTML(patid, notes)
        filename = '{}_notes'.format(patid)
        write_pdf(pjoin(outpath_extras, filename), pjoin(outpath_reports, filename), htmltext)
        tableOfContents[filename] = 'Therapy Notes Report'
    except IOError:
        print('No note found so no notes report created.')

    # generate the log data report
    print('Generating log data report')
    htmltext = checkHTML(patid, check)
    filename = '{}_LogData'.format(patid)
    write_pdf(pjoin(outpath_extras, filename), pjoin(outpath_reports, filename), htmltext)
    tableOfContents[filename] = 'Log Data Report'

    # generate the cover page
    htmltext = coverHTML(patid=patid, tableOfContents=tableOfContents)
    filename = '{}_00cover'.format(patid)
    write_pdf(pjoin(outpath_extras, filename), pjoin(outpath_reports, filename), htmltext)

    # generate the concatenated PDF
    print('Generating master PDF')
    try:
        check_output('/usr/bin/pdftk {0}/{1}_*.pdf cat output {0}/reports_{1}.pdf'.format(outpath_reports, patid),
                     shell=True)
    except CalledProcessError:
        print('Failed to generate master PDF, continuing anyway.')

    # generate the CSV output
    print('Generating CSV output')
    open(pjoin(outpath_extras, '{}_data.csv'.format(patid)), 'w').write(reportCSV(t=t))
    print('done')


def is_robot_running():
    try:
        check_output('/usr/bin/pgrep -x robot'.split())
        return True
    except CalledProcessError:
        return False


if __name__ == '__main__':
    # fdopen with bufsize 1 works around Tcl/Tk issue
    sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 1)
    parser = argparse.ArgumentParser(description='Process patient data.')
    parser.add_argument('patientid', type=str, help='patient id')
    parser.add_argument('--nocache', action='store_true', help='do not use cached PNGs')
    args = parser.parse_args()

    dopatient(args.patientid, args.nocache)
