#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2019-11-18 16:23:21
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import ShmPyCtrl.ShmPy as shm
import subprocess
import time

shm_path = './shm'

command = {
    'start_pos': (0, 0),
    'end_pos': (0, 0)
}

def set_shm_path(path):
    shm_path = path

def start_rtl():
    subprocess.run(['tclsh ./start.tcl'], shell=True)

def wshm(target, value):
    shm.send_command(shm.get_command(action='set', target=target, value=value, path=shm_path))

def set_default():
    wshm('no_safety_check', 1)
    wshm('stiff', 100)
    wshm('damp', 5)
    wshm('slot_max', 4)

def set_parameter(target, value):
    command[target] = value

def set_command(start_pos, end_pos):
    command['start_pos'] = start_pos
    command['end_pos'] = end_pos

def run_movebox():
    subprocess.run(['tclsh ./movebox.tcl '+str(command['start_pos'][0])+' '+str(command['start_pos'][1])\
    +' '+str(command['end_pos'][0])+' '+str(command['end_pos'][1])], shell=True)

def go_center():
    set_command((0, 0), (0, 0))
    run_movebox()

def go(direction):
    print('Re-centering, hold on.')
    go_center()
    time.sleep(5)
    if direction == 'left':
        print('going '+direction)
        set_command((0, 0), (-0.3, 0))
        run_movebox()
    elif direction == 'right':
        print('going '+direction)
        set_command((0, 0), (0.3, 0))
        run_movebox()
    elif direction == 'up':
        print('going '+direction)
        set_command((0, 0), (0, 0.3))
        run_movebox()
    elif direction == 'down':
        print('going '+direction)
        set_command((0, 0), (0, -0.3))
        run_movebox()

def stop():
    subprocess.run(['/opt/imt/robot/crob/stop'], shell=True)

if __name__ == '__main__':
    start_rtl()
    set_default()
    go('left')
    time.sleep(5)
    go('right')
    time.sleep(5)
    go('up')
    time.sleep(5)
    go('down')
    time.sleep(5)
    go_center()
    time.sleep(5)
    stop()
