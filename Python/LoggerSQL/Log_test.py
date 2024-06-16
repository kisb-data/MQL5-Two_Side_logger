from Libs import LoggerSQL
from random import randint
import time

# set static values
static_vals = {
    'Source': "Python",
    'Name': "LT",
    'Account': "51808207",
    'Symbol': "EURUSD",
    'Period': "H1"
}

# add cols if need to create table
cols = [{"id": "INTEGER PRIMARY KEY AUTOINCREMENT"}, {"Source": "TEXT"}, {"Type": "TEXT"}, {"Name": "TEXT"}, {"Account": "TEXT"}, {"Date": "TEXT"}, {"Time": "TEXT"}, {"Symbol": "TEXT"}, {"Period": "TEXT"}, {"Message": "TEXT"}]

# create logger class
logger = LoggerSQL.CLogger("C:\\Users\\balus\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\Files\\Log\\","Log", "LoggerTest", "Debug", True, cols, static_vals)

# data insertion
levels=["Debug", "Position", "Warning"]
for i in range(150):
    logger.add(levels[randint(0,2)], str(i)+" Python SQL test")
    #time.sleep(randint(1, 3))
