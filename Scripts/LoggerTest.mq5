//+------------------------------------------------------------------+
//|                     Copyright 2024, kisb-data                    |
//|                     kisbalazs.data@gmail.com                     |
//+------------------------------------------------------------------+

//--- insert libary
#include <kisb_data\\Log\\SYS_Logger_SQL.mqh>

//--- create class
CLogger         * Logger;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   Logger = new CLogger("Log", "Log", "LoggerTest", "LT", true, false);

   // Data insertion loop
   string levels[] = {"Debug", "Position", "Warning"};
   for(int i = 0; i < 100; i++)
     {
      int level_index = MathRand() % 3; 
      Logger.Add(levels[level_index], IntegerToString(/*MathRand()*/i) + " MQL SQL test");
     }
  
   delete Logger;
  }
