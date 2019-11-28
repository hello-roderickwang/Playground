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
        self.size = (self.x, self.y)
        self.connection_dict = {}
        self.dimension = 0
        self.build()

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
            self.dimension = 1
        # 2-dimensional
        else:
            for i in range(self.x):
                self.cluster.append([])
                for j in range(self.y):
                    self.cluster[i].append(Neurons.LIF())
            # check whether the cluster size is correct
            if len(self.cluster) * len(self.cluster[0]) != self.x * self.y:
                print('ERROR! Size of cluster is not correct.')
            self.dimension = 2

    def connect(self, pre_index, post_index):
        # if the dimension is 0, then there something wrong in the build function
        if self.dimension == 0:
            print('ERROR! Cluster dimension is illegal.')
        # 1-dimensional index:(pos, 0)
        elif self.dimension == 1:
            self.connection_dict[str(pre_index) + 'to' + str(post_index)] = Synapse.Synapse(
                self.cluster[pre_index[0]],
                self.cluster[post_index[0]]
            )
            cluster_pre = self.cluster[pre_index[0]]
            cluster_post = self.cluster[post_index[0]]
            synapse_pre = self.connection_dict[str(pre_index) + 'to' + str(post_index)].pre_neuron
            synapse_post = self.connection_dict[str(pre_index) + 'to' + str(post_index)].post_neuron
            if cluster_pre is not synapse_pre or cluster_post is not synapse_post:
                print('ERROR! Connection wrong.')
        # 2-dimensional index:(pos_x, pos_y)
        elif self.dimension == 2:
            self.connection_dict[str(pre_index) + 'to' + str(post_index)] = Synapse.Synapse(
                self.cluster[pre_index[0]][pre_index[1]],
                self.cluster[post_index[0]][post_index[1]]
            )
            cluster_pre = self.cluster[pre_index[0]][pre_index[1]]
            cluster_post = self.cluster[post_index[0]][post_index[1]]
            synapse_pre = self.connection_dict[str(pre_index) + 'to' + str(post_index)].pre_neuron
            synapse_post = self.connection_dict[str(pre_index) + 'to' + str(post_index)].post_neuron
            if cluster_pre is not synapse_pre or cluster_post is not synapse_post:
                print('ERROR! Connection wrong.')