from datetime import datetime
from Libs import SQLiteDataAccessExtLog
import os

class CLogger:
    
    # constructor
    def __init__(self, path, database, table, print_level, log_SQL, cols, static_vals):
        
        self.p_levels=["", "Debug", "Position", "Warning"]
        self.database = database
        self.table = table
        self.print_level = self.p_levels.index(print_level)
        self.log_SQL = log_SQL
        self.static_vals = static_vals
        self.buffer = []

        #create SQL access
        if not os.path.exists(path):
            os.makedirs(path)
        self.SQL = SQLiteDataAccessExtLog.DataAccess(path+database+".sqlite")
        
        # create table if is not exist
        self.SQL.ResetLastError()
        self.SQL.CreateTable(table, cols)
        if self.SQL.GetLastError()!="":
            print(f"Unable to open/create table {table}, error: "+self.SQL.GetLastError())
        else:
            self.print_it("Debug", f"Table exist ({table}).")

    # print log in terminal
    def print_it(self, level, message):
        if self.print_level>=self.p_levels.index(level):
            print(f"=======> {level}: {message}")

    #log entry, with static and current values
    def get_str(self, type_, msg):

        date_str = datetime.now().strftime("%Y-%m-%d")
        time_str = datetime.now().strftime("%H:%M:%S")
        cur_vals = {'Type': type_, 'Date': date_str, 'Time': time_str, 'Message': msg}

        cur_vals.update(self.static_vals)
        return cur_vals

    #add log entry
    def add(self, type, message):
        
        self.print_it(type, message)
        
        if self.log_SQL:
            self.SQL.ResetLastError()
            ret = self.SQL.Insert(self.table, [self.get_str(type, message)])

            if ret==None:
                self.buffer.append(self.get_str("Warning", "Can not insert row into database."))
                self.buffer.append(self.get_str(type, message))
                err = f"Unable to add row to database, table {self.table}, error: "+self.SQL.GetLastError()
                self.print_it("Warning", message)
                self.buffer.append(self.get_str("Warning", err))
            else:
                self.print_it(f"Debug", "Data Iserted ("+message+")")

    #flush buffer
    def flush(self):
        self.SQL.ResetLastError()
        if len(self.buffer)>0:
            ret=self.SQL.Insert(self.table, self.buffer)
            print(ret)
            if ret!=None:
                self.add("Debug", "Data Flused. (rows:"+str(len(self.buffer))+")")
                self.buffer = []


