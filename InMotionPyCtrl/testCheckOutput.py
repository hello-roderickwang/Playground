#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Date    : 2019-09-30 16:12:58
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @Github  : https://github.com/hello-roderickwang

import subprocess

if __name__ == '__main__':
    result = subprocess.check_output(["./testCheckOutput"], shell=True)
    print('result:', result)
    result = subprocess.run(["./testCheckOutput"], shell=True, capture_output=True)
    print('result:', result)
    print('result.stdout:', result.stdout)
    print('type of result.stdout:', type(result.stdout))
    string_output = result.stdout.decode('utf-8')
    print('string_output:', string_output)
    print('type of string_output:', type(string_output))