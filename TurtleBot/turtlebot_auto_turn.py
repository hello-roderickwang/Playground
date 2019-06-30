#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Date    : 2019-06-30 14:56:55
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @Github  : https://github.com/hello-roderickwang

import rospy
import numpy as np
from geometry_msgs.msg import Twist
from sensor_msgs.msg import LaserScan
from math import radians

class AutoTurn():
    def __init__(self):
        rospy.init_node('autoturn', anonymous=True)
        rospy.on_shutdown(self.shutdown)
        self.rate = rospy.Rate(5)
        self.data = []
        self.pub_navi = rospy.Publisher('/cmd_vel_mux/input/navi', Twist, queue_size=10)
        self.sub_laserscan = rospy.Subscriber('/scan', LaserScan, self.get_data)

    def get_data(self, msg):
        self.data = []
        for i in range(len(msg.ranges)):
            self.data.append(msg.ranges[i])

    def shutdown(self):
        rospy.loginfo('Stop Navigation!')
        self.pub_navi.publish(Twist())
        rospy.sleep(1)

    def down_sampling(self, method='MEDIAN', sample_num=30):
        self.translate_nan()
        sample_size = len(self.data)//sample_num
        remainder = len(self.data)%sample_num
        sample = []
        result = []
        for i in range(sample_num):
            sample.append(self.data[remainder//2+i*sample_size:remainder//2+(i+1)*sample_size])
            if method is 'MEDIAN':
                result.append(np.median(sample[i]))
            elif method is 'MEAN':
                result.append(np.mean(sample[i]))
            else:
                print 'ERROR! method can only be MEDIAN or MEAN.'
        return result

    def make_decision(self, sample):
        sigma = 3
        left = 0
        right = 0
        for i in range(len(sample)):
            if i < len(sample)//2:
                right += sample[i]
            else:
                left += sample[i]
        print 'left:', left, '\nright:', right
        if left == right:
            return 'straight'
        elif left < right:
            return 'right'
        else:
            return 'left'

    def translate_nan(self, threshold=10):
        for i in range(len(self.data)):
            if np.isnan(self.data[i]):
                self.data[i] = threshold

    def turn_left(self):
        action = Twist()
        action.linear.x = 0.1
        action.angular.z = radians(10)
        return action

    def turn_right(self):
        action = Twist()
        action.linear.x = 0.1
        action.angular.z = radians(-10)
        return action

    def keep_true(self):
        action = Twist()
        action.linear.x = 0.2
        return action

    def run(self):
        while not rospy.is_shutdown():
            decision = self.make_decision(self.down_sampling())
            if decision is 'left':
                rospy.loginfo('Going LEFT')
                for t in range(5):
                    self.pub_navi.publish(self.turn_left())
                    self.rate.sleep()
            elif decision is 'right':
                rospy.loginfo('Going RIGHT')
                for t in range(5):
                    self.pub_navi.publish(self.turn_right())
                    self.rate.sleep()
            else:
                print 'decision:', decision
                rospy.loginfo('Going STRAIGHT')
                for t in range(5):
                    self.pub_navi.publish(self.keep_true())
                    self.rate.sleep()

if __name__ == '__main__':
    autoturn = AutoTurn()
    autoturn.run()
