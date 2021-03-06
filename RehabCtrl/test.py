#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : Nov.26 2019
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang


import Neurons
import Synapse
import Cluster
import numpy as np
import matplotlib.pyplot as plt


if __name__ == '__main__':
    x = np.linspace(-np.pi, np.pi, 201)
    sin = (np.sin(x)+1)/2

    a = Neurons.LIF()
    b = Neurons.LIF()

    weight = 2

    connection = Synapse.Synapse(a, b)
    connection.set_weight(weight)

    v_a = []
    v_b = []

    for step in range(0, len(sin)):
        a.stimulate(sin[step])
        a.go()
        v_a.append(a.out)
        connection.go()
        b.go()
        v_b.append(b.out)

    plt.plot(range(len(v_a)), v_a, 'r')
    plt.plot(range(len(v_b)), v_b, 'g')
    plt.plot(range(len(sin)), sin, 'b')
    plt.xlabel('Time Steps')
    plt.ylabel('Voltage')
    plt.show()

    one = Cluster.Cluster(5)
    print('dimension of one: ', one.dimension)
    print('Size of 1D cluster: ', len(one.cluster))
    two = Cluster.Cluster(5, 5)
    print('dimension of two: ', two.dimension)
    print('size of 2D cluster is: ', len(two.cluster), ' * ', len(two.cluster[0]))

    one.connect((0, 0), (1, 0))
    two.connect((1, 1), (2, 2))
