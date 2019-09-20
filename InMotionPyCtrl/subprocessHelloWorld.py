#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Date    : 2019-09-19 16:37:35
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import subprocess

if __name__ == '__main__':
    # subprocess.call(["gcc", "HelloWorld.c"])
    # result = subprocess.call("./a.out")
    A = 1
    B = 2
    result = subprocess.run(["echo "+ str(A)+' '+ str(B)+' '+ "| ./HelloWorld"], shell=True)
    # result2 = subprocess.run("1")
    # result3 = subprocess.run("2")
    print(result)
    # print(result2)
    # print(result3)
