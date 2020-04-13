import pymongo

myclient = pymongo.MongoClient('mongodb://localhost:27017/')
mydb = myclient['CS527']
mycollect = mydb['COVID19']

# for i in range(32709):
#     country = mycollect.find()
#     pre = mycollect.find({Id:i})
#     post = mycollect.find({Id:i+1})

pre_country = mycollect.find({Id:1})['Country_Region']

for i in mycollect.find():
    country = i['Country_Region']
    if pre_country == country:
        dailyConfirmed = {'$set':{''}}