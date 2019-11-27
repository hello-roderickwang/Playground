#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : Nov.27 2019
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang


import Neurons
import Synapse


class Cluster:
    def __init__(self, x, y=0):
        self.cluster = []
        self.x = x
        self.y = y
        self.build()
        self.size = (self.x, self.y)
        self.connection_dict = {}

    # form a structure of neurons
    def build(self):
        # check if we have the legal dimension
        if self.x == 0:
            print('ERROR! You have to assign a cluster size.')
        # 1-dimensional
        elif self.y == 0:
            for i in range(self.x):
                self.cluster.append(Neurons.LIF())
            # check whether the cluster size is correct
            if len(self.cluster) != self.x:
                print('ERROR! Size of cluster is not correct.')
        # 2-dimensional
        else:
            for i in range(self.x):
                self.cluster.append([])
                for j in range(self.y):
                    self.cluster[i].append(Neurons.LIF())
            # check whether the cluster size is correct
            if len(self.cluster)*len(self.cluster[0]) != self.x*self.y:
                print('ERROR! Size of cluster is not correct.')

    def connect(self, pre_index, post_index):
        self.connection_dict[str(pre_index)+'to'+str(post_index)]=