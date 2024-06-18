//+------------------------------------------------------------------+
//|                                                                  |
//|                     Copyright 2024, kisb-data                    |
//|                     kisbalazs.data@gmail.com                     |
//|                                                                  |
//|                                                                  |
//|  This code is free software: you can redistribute it and/or      |
//|  modify it under the terms of the GNU General Public License as  |
//|  published by the Free Software Foundation, either version 3 of  |
//|  the License, or (at your option) any later version.             |
//|                                                                  |
//|  This code is distributed in the hope that it will be useful,    |
//|  but WITHOUT ANY WARRANTY; without even the implied warranty of  |
//|  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the    |
//|  GNU General Public License for more details.                    |
//|                                                                  |
//|  You should have received a copy of the GNU General Public       |
//|  License along with this code. If not, see                       |
//|  <http://www.gnu.org/licenses/>.                                 |
//|                                                                  |
//|  Additional terms:                                               |
//|  You may not use this software in products that are sold.        |
//|  Redistribution and use in source and binary forms, with or      |
//|  without modification, are permitted provided that the           |
//|  following conditions are met:                                   |
//|                                                                  |
//|  1. Redistributions of source code must retain the above         |
//|     copyright notice, this list of conditions and the following  |
//|     disclaimer.                                                  |
//|                                                                  |
//|  2. Redistributions in binary form must reproduce the above      |
//|     copyright notice, this list of conditions and the following  |
//|     disclaimer in the documentation and/or other materials       |
//|     provided with the distribution.                              |
//|                                                                  |
//|  3. Neither the name of the copyright holder nor the names of    |
//|     its contributors may be used to endorse or promote products  |
//|     derived from this software without specific prior written    |
//|     permission.                                                  |
//|                                                                  |
//|  4. Products that include this software may not be sold.         |
//|                                                                  |
//+------------------------------------------------------------------+

//ver 1.0


//insert libary
#include <kisb_data\\SQL\\SYS_SQLite_access.mqh>

/**********************************************************************************************************************
   the error message class
**********************************************************************************************************************/
class CLogger
  {

private:

   //create class
   CSQLite          * SQL;

   string            m_database;
   string            m_table;
   string            m_ID;
   bool              m_log_SQL;
   string            m_cols;
   bool              m_notify;
   bool              m_SQL_init;
   int               m_print_level;

   string            m_buffer[];

   void              PrintIt(const string  level, string message);
   string            GetPeriodStr();
   void              AddToBuffer(string message) {ArrayResize(m_buffer, ArraySize(m_buffer)+1); m_buffer[ArraySize(m_buffer)-1]=message;};
   string            str(string type, string str) ;

public:
   void              CLogger(const string path, const string database, const string table, const string ID, const bool log_SQL, const bool notify, const string print_level="");
   void             ~CLogger();
   void              Add(const string type, const string message);
   void              Flush();
   bool              SQL_init() {return(m_SQL_init);};
  };

/**********************************************************************************************************************
   constructor
**********************************************************************************************************************/
void CLogger::CLogger(const string path, const string database, const string table, const string ID, const bool log_SQL, const bool notify, const string print_level="")
  {
   //create class
   SQL = new CSQLite(false);
   
   //set print level
   m_print_level=4;
   if(print_level=="Warning")    m_print_level=3;
   if(print_level=="Position")   m_print_level=2;
   if(print_level=="Debug")      m_print_level=1;
   
   //set variables
   m_database=database;
   m_table=table;
   m_ID=ID;
   m_log_SQL=log_SQL;
   m_notify=notify;
   m_SQL_init=true;
   
   //open create database
   if(database!="")
      if(!SQL.OpenCreateDatabase(path, database))
         {Print("=======>"+"Failed to open database, error:"+DoubleToString(GetLastError(),0)+" ("+database+")");m_SQL_init=false; return;}

   //table data
   string cols[9] = {"Source", "Type", "Name", "Account", "Date", "Time", "Symbol", "Period", "Message"};
   string col_typs[9] = {"TEXT", "TEXT", "TEXT","TEXT", "TEXT", "TEXT", "TEXT", "TEXT", "TEXT"};

   //cols for reuse
   m_cols = "'Source','Type','Name','Account','Date','Time','Symbol','Period','Message'";

   //check if table exist, if no,t create

   if(database!="" && table!="")
   {
      SQL.LastErrorReset();
      if(!SQL.TableExist(table))
         if(!SQL.CreateTable(table, cols, col_typs))
            {Print("=======>"+"Failed to create table, error:"+DoubleToString(GetLastError(),0)+" ("+table+")");m_SQL_init=false;}
   }
  }

/**********************************************************************************************************************
   deconstructor
**********************************************************************************************************************/
void CLogger::~CLogger()
  {
   delete SQL;
  }
  
/**********************************************************************************************************************
   add message
**********************************************************************************************************************/
void CLogger::Add(const string type, string message)
  {
   //print in terminal
   int cur_level=0;
   if(type=="Warning")    cur_level=3;
   if(type=="Position")   cur_level=2;
   if(type=="Debug")      cur_level=1;

   if(cur_level>=m_print_level)
      PrintIt(type, message);

   //log in SQL
   if(m_log_SQL)
      if((!bool(MQLInfoInteger(MQL_TESTER)) && !bool(MQLInfoInteger(MQL_OPTIMIZATION))))
        {
         string row=str(type, message);
         //if can not insert add to buffer insert later
         SQL.LastErrorReset();
         if(!SQL.IsLocked())
            if(!SQL.InsertData(m_table, m_cols, row))
              {
               AddToBuffer(str("Warning", SQL.LastError()));
               AddToBuffer(row);
              }
        }

   //push notify if enabled
   if(m_notify)
      if(TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
         if(SendNotification(message))
            return;
         else
           {
            string message="Failed to send notification, error:"+DoubleToString(GetLastError(),0);
            Print("=======>"+message);
            AddToBuffer(str("Warning", message));
           }
  }

/**********************************************************************************************************************
   create string message
**********************************************************************************************************************/
string CLogger::str(const string type, string message)
  {
  
   string date = TimeToString(TimeCurrent(),TIME_DATE); 
   StringReplace(date,".","-");
   string ret ="";
   
   ret+="('"+"MQL"+"','"+type+"','"+m_ID+"','"+DoubleToString(AccountInfoInteger(ACCOUNT_LOGIN),0)+"','"+date+"','"+TimeToString(TimeCurrent(),TIME_MINUTES|TIME_SECONDS)+"','"+Symbol()+"','"+GetPeriodStr()+"','"+message+"');";
   
   return(ret);
  }
/**********************************************************************************************************************
   add rows from buffer
**********************************************************************************************************************/
void CLogger::Flush()
  {
   //add rows one by one and resize buffer if included
   int size=ArraySize(m_buffer);
   int count=0;
   if(size!=0)
      while(count<size)
        {
         string row=m_buffer[0];
         if(SQL.InsertData(m_table, m_cols, row))
            ArrayCopy(m_buffer, m_buffer, 0, 1);
         ArrayResize(m_buffer, ArraySize(m_buffer)-1);
         count++;
        }
  }

/**********************************************************************************************************************
   print in terminal
**********************************************************************************************************************/
void CLogger::PrintIt(const string level, string message)
  {

   //if message is too long take only the first and last part
   if(StringLen(message)>180)
      message=StringSubstr(message,0,164)+"....."+StringSubstr(message,StringLen(message)-(16),16);

   //print message
   Print("=  =======> "+level+": "+message);
  }

/**********************************************************************************************************************
   return period as string
**********************************************************************************************************************/
string CLogger::GetPeriodStr()
  {
   return(StringSubstr((EnumToString(Period())), 7));
  }

//+------------------------------------------------------------------+
