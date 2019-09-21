#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Date    : 2019-09-21 00:25:29
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @Github  : https://github.com/hello-roderickwang

import subprocess

def get_command(action, target, value=0, path='./shm'):
    action_cmd = ''
    target_cmd = target
    value_cmd = str(value)
    path_cmd = path
    if action is 'get' or action is 'g':
        action_cmd = 'get'
        cmd = 'echo '+action_cmd+' '+target_cmd+' | '+path_cmd
    elif action is 'set' or action is 's':
        action_cmd = 'set'
        cmd = 'echo '+action_cmd+' '+target_cmd+' '+value_cmd+' | '+path_cmd
    elif action is 'allget' or action is 'a':
        cmd = 'echo '+action_cmd+' | '+path_cmd
    else:
        cmd = ''
    return cmd

def send_command(cmd):
    if cmd is '':
        print('ERROR! UNKNOWN COMMAND!')
    else:
        subprocess.run([cmd], shell=True)

# if __name__ == '__main__':