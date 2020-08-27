import collections

# Parking Dilemma
def parkingDilemma(parkingPos, k):
    parkingPos.sort()
    minRoof = parkingPos[-1]
    for i in range(len(parkingPos)-k+1):
        minRoof = min(minRoof, parkingPos[i+k-1] - parkingPos[i] + 1)
    return minRoof

# Separating Students
def separatingStudent(students):
    L = len(students)
    pivot = sum(students)
    leftSum, rightSum = sum(students[:pivot+1]), sum(students[-pivot:])
    left = []
    right = []
    if leftSum > rightSum:
        for i in range(pivot):
            if students[i] == 0:
                left.append(i)
        for i in range(pivot + 1, L):
            if students[i] == 1:
                right.append(i)
    else:
        for i in range(pivot):
            if students[i] == 1:
                left.append(i)
        for i in range(pivot + 1, L):
            if students[i] == 0:
                right.append(i)
    ans = 0
    for i in range(len(left)):
        ans += right[i] - left[i]
    return ans

# Aladdin and his carpet (LC134)
def Aladdin(magic, dist):
    if sum(magic) < sum(dist):
        return -1
    cur = 0
    total = 0
    starter = 0
    for i in range(len(magic)):
        diff = magic[i] - dist[i]
        cur += diff
        total += diff
        if cur < 0:
            starter = i + 1
            cur = 0
    return starter if total >= 0 else -1

# Meandering Array
def meaderingArray(array):
    array.sort()
    ans = []
    for i in range(len(array)//2):
        ans.append(array[-(i + 1)])
        ans.append(array[i])
    if len(array) % 2 == 1:
        ans.append(array[i+1])
    return ans

# Partitioning Array
def partitioningArray(array, k):
    counter = collections.Counter(array)
    if len(array) % k != 0:
        return 'NO'
    L = len(array) // k
    for key in counter.keys():
        if counter[key] > L:
            return 'NO'
    return 'YES'

# Purchasing Supplies
def purchasingSupplies(budget, unitPrice, exchangePrice):
    ans = budget // unitPrice
    used = ans
    leftover = 0
    while used + leftover >= exchangePrice:
        used, leftover = divmod(used + leftover, exchangePrice)
        ans += used
    return ans

# Shifting String
def shiftingString(s, leftShifts, rightShifts):
    numOperation = abs(leftShifts - rightShifts) % len(s)
    return s[numOperation:] + s[:numOperation] if leftShifts > rightShifts else s[-numOperation:] + s[:-numOperation]

# Who's the closest
def findClosest(s, tar):
    dic = {}
    for i in range(len(s)):
        if s[i] not in dic:
            dic[s[i]] = [i]
        else:
            dic[s[i]].append(i)
    ans = []
    for index in tar:
        tmp = dic[s[index]].index(index)
        if tmp + 1 >= len(dic[s[index]]) or (dic[s[index]][tmp] - dic[s[index]][tmp-1]) <= (dic[s[index]][tmp+1] - dic[s[index]][tmp]):
            ans.append(dic[s[index]][tmp-1])
        else:
            ans.append(dic[s[index]][tmp+1])
    return ans


if __name__ == '__main__':
    # Parking Dilemma
    # parkingPos = [2, 10, 8, 17]
    # print(parkingDilemma(parkingPos, 2))

    # Separating Students
    # students = [1, 1, 1, 1, 0, 0, 0, 0]
    # students = [1, 1, 1, 1, 0, 1, 0, 1]
    # students = [1, 0, 1, 0, 0, 0, 0, 1]
    # print(separatingStudent(students))

    # Aladdin and his carpet
    # magic = [1, 2, 3, 4, 5]
    # dist = [3, 4, 5, 1, 2]
    # magic = [2, 3, 4]
    # dist = [3, 4, 3]
    # print(Aladdin(magic, dist))

    # Meandering Array
    # array = [-1, 1, 2, 3, -5]
    # array = [5, 2, 7, 8, -2, 25, 25]
    # print(meaderingArray(array))

    # Partitioning Array
    # array = [1, 2, 2, 4, 6]
    # print(partitioningArray(array, 3))

    # Purchasing Supplies
    # budget, unitPrice, exchangePrice = 6, 2, 2
    # print(purchasingSupplies(budget, unitPrice, exchangePrice))

    # Shifting String
    # s = 'abcde'
    # print(shiftingString(s, 10000, 20003))

    # Who's the closest
    s = 'hackerrank'
    tar = [4, 1, 6, 8]
    tar = [3, 0, 5, 7]
    print(findClosest(s, tar))