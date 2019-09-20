#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2019-09-20 15:21:38
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import subprocess

if __name__ == '__main__':
    movement = []
    movement.append(subprocess.run(["echo set test_raw_torque 1 | ./crob/shm"], shell=True))
    sleep(500)
    movement.append(subprocess.run(["set raw_torque_volts_s 1"], shell=True))#s=1, e=0
    sleep(1000)
    movement.append(subprocess.run(["set raw_torque_volts_e 1"], shell=True))#s=1, e=1
    sleep(1000)
    movement.append(subprocess.run(["set raw_torque_volts_s 0"], shell=True))#s=0, e=1
    sleep(1000)
    movement.append(subprocess.run(["set raw_torque_volts_e 0"], shell=Ture))#s=0, e=0
    sleep(1000)
    movement.append(subprocess.run(["ser test_raw_torque 0"], shell=Ture))
    sleep(500)
    print(movement)