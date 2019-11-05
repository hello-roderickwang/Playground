#!/usr/bin/python

# html tools
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from string import Template
import datetime

# a bunch of functions to generate html tags

# this is taken pretty much verbatim from the old Tcl code.
# there are probably 9999 libraries which do this, but what we
# need is so simple, there's little reason not to just implement it
# ourselves and not deal with extra complexity.


def tag(t, item, arg=''):
    return Template('<$t $arg>$item</$t>\n').substitute(t=t, item=item, arg=arg)


def th(item):
    return tag('th', item)


def td(item):
    return tag('td', item)


def trow(*items):
    return tag('tr', ''.join([td(x) for x in items]))


def ctrow(*items):
    return tag('tr', ''.join([td(x) for x in items]), 'align=center')


def thead(*items):
    return tag('tr', ''.join([th(x) for x in items]))


def comment(item):
    return '<!-- ' + item + ' -->\n'


def img(filename, w, h):
    return Template('<img src="$filename" width="$w" height="$h" />').substitute(filename=filename, w=w, h=h)


def html_begin(title):
    return '<html>' + tag('head', tag('title', title)) + '<body>'


def html_end():
    return '</body></html>'


def imt_html_cpr_str():
    return '<p>Copyright &copy; 2010-{} Interactive Motion Technologies, Inc.'.format(datetime.date.today().year)
