import csv

# with open('./COVID19_Excel.csv') as csvfile:
#     readCSV = csv.reader(csvfile, delimiter=',')
#     pre_state, pre_country = '', ''
#     file = []
#     for row in readCSV:
#         if int(row[7]) < 0:
#             if pre_state != row[1] or pre_country != row[2]:
#                 row[7] = row[5]
#         if int(row[8]) < 0:
#             if pre_state != row[1] or pre_country != row[2]:
#                 row[8] = row[6]
#         pre_state, pre_country = row[1], row[2]
#         file.append(row)
#
# with open('./COVID19_Excel_processed.csv', 'w') as csvfile:
#     writerCSV = csv.writer(csvfile, delimiter=',')
#     writerCSV.writerows(file)



with open('./COVID19_Excel_processed.csv') as csvfile:
    readCSV = csv.reader(csvfile, delimiter=',')
    file = []
    for row in readCSV:
        level = []
        level.append(row[2]) #Country_Region
        level.append(row[4]) #WeekOfYear
        level.append(row[7]) #ConfirmedDaily
        level.append(row[8]) #FatalitiesDaily
        file.append(level)

pre_woy = int(file[0][1])
pre_country = file[0][0]
sum_cd, sum_fd = 0, 0
processed = []
for row in file:
    if pre_woy == int(row[1]):
        sum_cd += int(row[2])
        sum_fd += int(row[3])
    else:
        processed.append([pre_country, pre_woy, sum_cd, sum_fd])
        pre_country = row[0]
        pre_woy = int(row[1])
        sum_cd = int(row[2])
        sum_fd = int(row[3])
processed.append([pre_country, pre_woy, sum_cd, sum_fd])

with open('./COVID_19_aggr.csv', 'w') as csvfile:
    writerCSV = csv.writer(csvfile, delimiter=',')
    writerCSV.writerows(processed)

