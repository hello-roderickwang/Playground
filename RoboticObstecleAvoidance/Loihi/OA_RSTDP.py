#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Date    : 2019-07-22 00:21:10
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @Github  : https://github.com/hello-roderickwang

# import Intel Loihi API
import nxsdk.api.n2a as nx
# import ROS
import rospy
from geometry_msgs.msg import Twist
# import other libs
import numpy as np
import time
import os


if __name__ == '__main__':