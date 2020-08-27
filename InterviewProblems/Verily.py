# LC 239. Sliding Window Maximum Difference
# Given an array nums, there is a sliding window of size k which is moving from the very left of the array to the very
# right. You can only see the k numbers in the window. Each time the sliding window moves right by one position. Return
# the max sliding window.
#
# Input: nums = [1,3,-1,-3,5,3,6,7], and k = 3
# Output: [4,6,8,8,3,4]
# Explanation:
#
# Window position                Max
# ---------------               -----
# [1  3  -1] -3  5  3  6  7       3
#  1 [3  -1  -3] 5  3  6  7       3
#  1  3 [-1  -3  5] 3  6  7       5
#  1  3  -1 [-3  5  3] 6  7       5
#  1  3  -1  -3 [5  3  6] 7       6
#  1  3  -1  -3  5 [3  6  7]      7

def maxDifferenceSlidingWindow(nums, k):
    # Brute Force
    # ans = []
    # for i in range(len(nums) - k + 1):
    #     tmp = nums[i:i + k]
    #     ans.append(max(tmp) - min(tmp))
    # return ans

    # # Using Heap
    # import heapq
    # ans = []
    # minHeap, maxHeap = [], []
    # for i in range(k):
    #     minHeap.append([nums[i], i])
    #     maxHeap.append([nums[i]*-1, i])
    # heapq.heapify(minHeap)
    # heapq.heapify(maxHeap)
    # ans.append(-1*maxHeap[0][0]-minHeap[0][0])
    # for i in range(k, len(nums)):
    #     heapq.heappush(minHeap, [nums[i], i])
    #     heapq.heappush(maxHeap, [nums[i]*-1, i])
    #     maxVal, maxIndex = maxHeap[0]
    #     while maxIndex <= i-k:
    #         heapq.heappop(maxHeap)
    #         maxVal, maxIndex = maxHeap[0]
    #     minVal, minIndex = minHeap[0]
    #     while minIndex <= i-k:
    #         heapq.heappop(minHeap)
    #         minVal, minIndex = minHeap[0]
    #     # print('maxVal:', maxVal, ' minVal:', minVal)
    #     ans.append(-1*maxVal-minVal)
    # return ans

    # Deque - Monotone Stack
    from collections import deque
    maxDeque, minDeque = deque(), deque()
    # we have to always make sure it's a monotone stack
    for i in range(k):
        while maxDeque and nums[maxDeque[-1]] < nums[i]:
            maxDeque.pop()
        maxDeque.append(i)
        while minDeque and nums[minDeque[-1]] > nums[i]:
            minDeque.pop()
        minDeque.append(i)
    ans = [nums[maxDeque[0]]-nums[minDeque[0]]]
    for i in range(k, len(nums)):
        if maxDeque and i-k == maxDeque[0]:
            maxDeque.popleft()
        while maxDeque and nums[maxDeque[-1]] < nums[i]:
            maxDeque.pop()
        maxDeque.append(i)
        if minDeque and i-k == minDeque[0]:
            minDeque.popleft()
        while minDeque and nums[minDeque[-1]] > nums[i]:
            minDeque.pop()
        minDeque.append(i)
        print('maxDeque[0]:', maxDeque[0], ' ,minDeque[0]:', minDeque[0])
        ans.append(nums[maxDeque[0]]-nums[minDeque[0]])
    print('minDeque:', minDeque)
    print('maxDeque:', maxDeque)
    return ans



# DFS，给一个K，K 是总播放分钟，给int[int[]], 每一个一维数组代表一个广告，一维数组中有a,b， a是这个广告的时长(分钟， b是广告的报价，
# 要求K分钟里最大利润，然后播每一个广告是至少播放时长/2， 比如10分钟，至少要播5分钟
#
# input = [[5,10],[8,8],[8,12],[10,15],[3,20],[5,12],[8,12]], k = 17
# output = 258

def maxAdsProfit(input, k):
    from math import ceil
    array = []
    for mins, price in input:
        array.append([price, mins])
    array.sort(reverse=True)

    def DFS(array, curK):
        if not array:
            return 0
        for i in range(len(array)):
            if ceil(array[i][1]/2) > curK:
                continue
            else:
                if array[i][1] <= curK:
                    curPrice = array[i][0]*array[i][1]
                    nxt = DFS(array[i+1:], curK-array[i][1])
                    if nxt == -1:
                        continue
                    return curPrice+nxt
                else:
                    return array[i][0]*curK
        return -1

    return DFS(array, k)



# 给一堆事件和时间，然后如果最近十秒没出现过这个事件就println要是出现过update时间， 输入是String[], Time[]，一一对应，
# 比如 food- 01 shower- 04, food-11, run-15, 还有一个要求是每次遇到新的事件，要把已存下的事件中超过十秒(时间差大于10)的删除,
# 比如我遇到run-15，就要把shower-4删掉
#
# event = ['eat', 'shower', 'run', 'shower', 'drive', 'eat', 'drive', 'eat', 'shower']
# time = [2, 4, 5, 7, 11, 14, 16, 19, 22]
# output = ['eat', 'run', 'shower']

def printPreviousEvent(event, time):
    if len(event) != len(time):
        print('Event and Time should be same length!')
    dict_time = {}
    list_event = []
    for i in range(len(event)):
        if not list_event:
            list_event.append([event[i], time[i]])
        else:
            while time[i] - list_event[0][1] > 10:
                e, t = list_event.pop(0)
                if time[i] - dict_time[e] > 10:
                    print(e)
            else:
                list_event.append([event[i], time[i]])
        if event[i] not in dict_time:
            dict_time[event[i]] = time[i]
        else:
            dict_time[event[i]] = time[i]



# Let's say you're an environmental engineer trying to assist in laying out infrastructure in some village.
# The village has N houses, each which needs a water supply. A house can receive water if:
# - A well is built there
# - There is some path of pipes to a house with a water well
#
# You work with a contractor and figure out
# - The cost to build a well at house (well_cost) length N
# - The cost of the pipe to connect house and house[j] (pipe_cost[j]) NxN
#
# What's the cheapest way to make sure every house in the village is connected to a water supply?



# Imagine a person travels from city A to city B by train. There are N stations between city A and B. He may get off
# the train at any of the station, but he would not get off in neighboring stations. He can not travel backward
# neither. How many different ways he can travel?

# N = 5
# output = 5

def waysToTravel(N):
    if N <= 2:
        return 0
    dp = [0 for _ in range(N+2)]
    dp[0], dp[1] = 1, 0
    for i in range(2, N+2):
        for j in range(0, i-1):
            dp[i] += dp[j]
    return dp[-1]


if __name__ == '__main__':
    # # Sliding Window Maximum Difference
    # nums = [1, 3, -1, -3, 5, 3, 6, 7]
    # k = 3
    # print(maxDifferenceSlidingWindow(nums, k))

    # # Maximum Profit from Ads
    # input = [[5,10],[8,8],[8,12],[10,15],[3,20],[5,12],[8,12]]
    # k = 17
    # print(maxAdsProfit(input, k))

    # # Print Previous Event
    # event = ['eat', 'shower', 'run', 'shower', 'drive', 'eat', 'drive', 'eat', 'shower']
    # time = [2, 4, 5, 7, 11, 14, 16, 19, 22]
    # printPreviousEvent(event, time)

    # Find Ways to Travel
    N = 5
    print(waysToTravel(N))