#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : Nov.26 2019
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang


class LIF:
    def __init__(self):
        self.v = 0
        self.i = 0
        self.v_threshold = 10
        self.v_rest = 0
        self.r = 1
        self.c = 5
        self.tau = self.r * self.c
        self.is_firing = False

    def update(self):
        self.v = self.v + (-1 * self.v + self.r * self.i) / self.tau

    def stimulate(self, i_new):
        self.i += i_new

    def reset(self):
        self.v = self.v_rest

    def check_firing(self):
        if self.v >= self.v_threshold:
            self.is_firing = True
            self.reset()
        else:
            self.is_firing = False

    def go(self):
        self.update()
        self.check_firing()

