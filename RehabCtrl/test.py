#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : Nov.26 2019
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang


import Neurons
import Synapse
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
        v_a.append(a.v)
        connection.go()
        b.go()
        v_b.append(b.v)

    plt.plot(range(len(v_a)), v_a, 'r')
    plt.plot(range(len(v_b)), v_b, 'g')
    plt.plot(range(len(sin)), sin, 'b')
    plt.xlabel('Time Steps')
    plt.ylabel('Voltage')
    plt.show()
