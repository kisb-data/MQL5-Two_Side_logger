//+------------------------------------------------------------------+
//|                     Copyright 2024, kisb-data                    |
//|                     kisbalazs.data@gmail.com                     |
//+------------------------------------------------------------------+

//ver 1.0

/*
   print warnings/infos/debug infos
   log warnings/infos/debug infos
   different alert types
*/

/**********************************************************************************************************************
   the error message class
**********************************************************************************************************************/
class CLogger {


             
   public:   
                  
             static void   Set(const string logLevel,const string notifyLevel, const string  notificationMethod, const string id, const string path, const bool log_file=false); 
             static void   Add(const string level, const string message, const string add_info="", const int error_code=-1);
             static string GetLogLevel();

   private:
 
             struct Code
             {
                  int code;      // Error code
                  string desc;   // Description of the error code
             };
             
             static string m_logLevel;
             static string m_notifyLevel;
             static string m_notificationMethod; 
             static string m_filename;
             static string m_id;
             static bool   m_log_file;
             
             static void   PrintIt(const string  level, string message);
             static string GetPeriodStr();
             static void   WriteToFile(const string fileName, const string text);
             static void   Notify(const string  level,const string message);   
             static string ErrorDesc(const int code);       
};

/**********************************************************************************************************************
   set functions
**********************************************************************************************************************/
static void CLogger::Set(const string logLevel,const string notifyLevel, const string  notificationMethod, const string id, const string path, const bool log_file) {
  
   m_logLevel=logLevel;
   m_notifyLevel=notifyLevel;
   m_notificationMethod=notificationMethod;
   m_filename=path;
   m_id=id;
   m_log_file=log_file;
}
     
/**********************************************************************************************************************
   add message
**********************************************************************************************************************/
static void CLogger::Add(const string level, string message, const string add_info="", const int error_code=-1) {
   
   //get error description
   if(error_code!=-1) message = message+" "+CLogger::ErrorDesc(error_code);
      
   //in case of debug add libary/subrutine/line data
   if(add_info!="" && m_logLevel=="DEBUG") message=message+"   ["+add_info+"]";

   //log in file 
   if(m_log_file)
      if((!bool(MQLInfoInteger(MQL_TESTER)) && !bool(MQLInfoInteger(MQL_OPTIMIZATION)))) {WriteToFile(m_filename, message);}

   //no logging
   if(m_logLevel=="NOLOG") return;

   int l=0;
   int ml=0;
   int mnl=0;
   
   if(level=="Info")        l=1;
   if(level=="Warning")     l=2;
   
   if(m_logLevel=="INFO")    ml=1;
   if(m_logLevel=="WARNING") ml=2;

   if(m_notifyLevel=="INFO")    mnl=1;
   if(m_notifyLevel=="WARNING") mnl=2;
   
   if(l>=ml)  PrintIt(level, message);
   if(l>=mnl) Notify(level, message);
}

/**********************************************************************************************************************
   write or print or booth
**********************************************************************************************************************/
static void CLogger::PrintIt(const string level, string message) {
   
   //if message is too long take only the first and last part
   if(StringLen(message)>180) message=StringSubstr(message,0,164)+"....."+StringSubstr(message,StringLen(message)-(16),16);
   
   //print message
   Print("= "+m_id+" =======> "+level+": "+message);
}

/**********************************************************************************************************************
   write or print or booth
**********************************************************************************************************************/
static string CLogger::GetLogLevel() {
   return(m_logLevel);
}


/**********************************************************************************************************************
   return period as string
**********************************************************************************************************************/
static string CLogger::GetPeriodStr() {
   
   ResetLastError();
   string periodStr=DoubleToString(Period(),0);
   if(GetLastError()!=0) periodStr=(string)Period();
   StringReplace(periodStr,"PERIOD_","");
   return periodStr;
}
     
/**********************************************************************************************************************
   write in log file
**********************************************************************************************************************/
static void CLogger::WriteToFile(const string fileName, const string text) {
   
   ResetLastError();
   string fullText=TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS)+", "+Symbol()+" "+GetPeriodStr()+", "+text;
   int fileHandle=FileOpen(fileName,FILE_TXT|FILE_READ|FILE_WRITE|FILE_COMMON);
   bool result=true;
   if(fileHandle!=INVALID_HANDLE)
   {
      // attempt to place a file pointer in the end of a file            
      if(!FileSeek(fileHandle,0,SEEK_END)) Print("=======>"+"WARNING: FileSeek() is failed, error #",GetLastError(),"; text = \"",fullText,"\"; fileName = \"",fileName,"\"");
      // attempt to write a text in a file
      if(FileWrite(fileHandle,fullText)==0) Print("=======>"+"WARNING: FileWrite() is failed, error #",GetLastError(),"; text = \"",fullText,"\"; fileName = \"",fileName,"\"");
      FileClose(fileHandle);
   }
   else
      Print("=======>"+"WARNING: FileOpen() is failed, error #",GetLastError(),"; text = \"",fullText,"\"; fileName = \"",fileName,"\"");
}
     
/**********************************************************************************************************************
   execute notification
**********************************************************************************************************************/
static void CLogger::Notify(const string  level,const string message) {
   
   if(m_notificationMethod=="NONE")  return;
      
   string fullMessage=TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS)+", "+Symbol()+" ("+GetPeriodStr()+"), "+message;

   if(m_notificationMethod=="MAIL")
      if(TerminalInfoInteger(TERMINAL_EMAIL_ENABLED))
         if(SendMail("Logger",fullMessage))
            return;
         else Print("=======>"+"WARNING: Failed to send mail, error #",GetLastError()); 

   if(m_notificationMethod=="PUSH")
      if(TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
         if(SendNotification(fullMessage))
            return;
         else Print("=======>"+"WARNING: Failed to send notification, error #",GetLastError());  
            
   if(m_notificationMethod=="ALERT") 
      Alert(message); 
}

/**********************************************************************************************************************
   set static variables to default
**********************************************************************************************************************/
static string CLogger::m_logLevel="";
static string CLogger::m_notifyLevel="";
static string CLogger::m_notificationMethod=""; 
static string CLogger::m_filename=""; 
static string CLogger::m_id="";
static bool   CLogger::m_log_file=true;
   
/**********************************************************************************************************************
   set error codes
**********************************************************************************************************************/
static string CLogger::ErrorDesc(const int code) {
   
   string e = "";
   switch(code)
   {
      case 0:	return("");
   	case 10004:	e = "Requote"; break;
      case 10006:	e = "Request rejected"; break;
      case 10007:	e = "Request canceled by trader"; break;
      case 10008:	e = "Order placed"; break;
      case 10009:	e = "Request is completed"; break;
      case 10010:	e = "Request is partially completed"; break;
      case 10011:	e = "Request processing error"; break;
      case 10012:	e = "Request canceled by timeout"; break;
      case 10013:	e = "Invalid request"; break;
      case 10014:	e =  "Invalid volume in the request"; break;
      case 10015:	e = "Invalid price in the request"; break;
      case 10016:	e = "Invalid stops in the request"; break;
      case 10017:	e = "Trade is disabled"; break;
      case 10018:	e = "Market is closed"; break;
      case 10019:	e = "There is not enough money to fulfill the request"; break;
      case 10020:	e = "Prices changed"; break;
      case 10021:	e = "There are no quotes to process the request"; break;
      case 10022:	e = "Invalid order expiration date in the request"; break;
      case 10023:	e = "Order state changed"; break;
      case 10024:	e = "Too frequent requests"; break;
      case 10025:	e = "No changes in request"; break;
      case 10026:	e = "Autotrading disabled by server"; break;
      case 10027:	e = "Autotrading disabled by client terminal"; break;
      case 10028:	e = "Request locked for processing"; break;
      case 10029:	e = "Order or position frozen"; break;
      case 10030:	e = "Invalid order filling type"; break;
   
      // Common Errors
      case 4001:	e = "Unexpected internal error"; break;
      case 4002:	e = "Wrong parameter in the inner call of the client terminal function"; break;
      case 4003:	e = "Wrong parameter when calling the system function"; break;
      case 4004:	e = "Not enough memory to perform the system function"; break;
      case 4005:	e = "The structure contains objects of strings and/or dynamic arrays and/or structure of such objects and/or classes"; break;
      case 4006:	e = "Array of a wrong type, wrong size, or a damaged object of a dynamic array"; break;
      case 4007:	e = "Not enough memory for the relocation of an array, or an attempt to change the size of a static array"; break;
      case 4008:	e = "Not enough memory for the relocation of string"; break;
      case 4009:	e = "Not initialized string"; break;
      case 4010:	e = "Invalid date and/or time"; break;
      case 4011:	e = "Requested array size exceeds 2 GB"; break;
      case 4012:	e = "Wrong pointer"; break;
      case 4013:	e = "Wrong type of pointer"; break;
      case 4014:	e = "System function is not allowed to call"; break;
   
      // Charts
      case 4101:	e = "Wrong chart ID"; break;
      case 4102:	e = "Chart does not respond"; break;
      case 4103:	e = "Chart not found"; break;
      case 4104:	e = "No Expert Advisor in the chart that could handle the event"; break;
      case 4105:	e =  "Chart opening error"; break;
      case 4106:	e = "Failed to change chart symbol and period"; break;
      case 4107:	e = "Wrong parameter for timer"; break;
      case 4108:	e = "Failed to create timer"; break;
      case 4109:	e = "Wrong chart property ID"; break;
      case 4110:	e = "Error creating screenshots"; break;
      case 4111:	e = "Error navigating through chart"; break;
      case 4112:	e = "Error applying template"; break;
      case 4113:	e = "Subwindow containing the indicator was not found"; break;

      // Graphical Objects
      case 4201:	e = "Error working with a graphical object"; break;
      case 4202:	e = "Graphical object was not found"; break;
      case 4203:	e = "Wrong ID of a graphical object property"; break;
      case 4204:	e = "Unable to get date corresponding to the value"; break;
      case 4205:	e = "Unable to get value corresponding to the date"; break;
      
      // MarketInfo   
      case 4301:	e = "Unknown symbol"; break;
      case 4302:	e = "Symbol is not selected in MarketWatch"; break;
      case 4303:	e = "Wrong identifier of a symbol property"; break;
      case 4304:	e = "Time of the last tick is not known (no ticks)"; break;
   
      // History Access
      case 4401:	e = "Requested history not found"; break;
      case 4402:	e = "Wrong ID of the history property"; break;
      
      // Global_Variables
      case 4501:	e = "Global variable of the client terminal is not found"; break;
      case 4502:	e = "Global variable of the client terminal with the same name already exists"; break;
      case 4510:	e = "Email sending failed"; break;
      case 4511:	e = "Sound playing failed"; break;
      case 4512:	e = "Wrong identifier of the program property"; break;
      case 4513:	e = "Wrong identifier of the terminal property"; break;
      case 4514:	e = "File sending via ftp failed"; break;
   
   
      // Custom Indicator Buffers
      case 4601:	e = "Not enough memory for the distribution of indicator buffers"; break;
      case 4602:	e = "Wrong indicator buffer index"; break;
      
      // Custom Indicator Properties
      case 4603:	e = "Wrong ID of the custom indicator property"; break;
      
      // Account
      case 4701:	e = "Wrong account property ID"; break;
      case 4751:	e = "Wrong trade property ID"; break;
      case 4752:	e = "Trading by Expert Advisors prohibited"; break;
      case 4753:	e = "Position not found"; break;
      case 4754:	e = "Order not found"; break;
      case 4755:	e = "Deal not found"; break;
      case 4756:	e = "Trade request sending failed"; break;
      case 4757:	e = "Timeout exceeded when selecting (searching) specified data"; break;
      
      // Indicators
      case 4801:	e = "Unknown symbol"; break;
      case 4802:	e = "Indicator cannot be created"; break;
      case 4803:	e = "Not enough memory to add the indicator"; break;
      case 4804:	e = "The indicator cannot be applied to another indicator"; break;
      case 4805:	e = "Error applying an indicator to chart"; break;
      case 4806:	e = "Requested data not found"; break;
      case 4807:	e = "Wrong index of the requested indicator buffer"; break;
      case 4808:	e = "Wrong number of parameters when creating an indicator"; break;
      case 4809:	e = "No parameters when creating an indicator"; break;
      case 4810:	e = "The first parameter in the array must be the name of the custom indicator"; break;
      case 4811:	e = "Invalid parameter type in the array when creating an indicator"; break;
      
      // Depth of Market
      case 4901:	e = "Depth Of Market can not be added"; break;
      case 4902:	e = "Depth Of Market can not be removed"; break;
      case 4903:	e = "The data from Depth Of Market can not be obtained"; break;
      case 4904:	e = "Error in subscribing to receive new data from Depth Of Market"; break;
      
      // File Operations
      case 5001:	e = "More than 64 files cannot be opened at the same time"; break;
      case 5002:	e = "Invalid file name"; break;
      case 5003:	e = "Too long file name"; break;
      case 5004:	e = "File opening error"; break;
      case 5005:	e = "Not enough memory for cache to read"; break;
      case 5006:	e = "File deleting error"; break;
      case 5007:	e = "A file with this handle was closed, or was not opened at all"; break;
      case 5008:	e = "Wrong file handle"; break;
      case 5009:	e = "The file must be opened for writing"; break;
      case 5010:	e = "The file must be opened for reading"; break;
      case 5011:	e = "The file must be opened as a binary one"; break;
      case 5012:	e = "The file must be opened as a text"; break;
      case 5013:	e = "The file must be opened as a text or CSV"; break;
      case 5014:	e = "The file must be opened as CSV"; break;
      case 5015:	e = "File reading error"; break;
      case 5016:	e = "String size must be specified, because the file is opened as binary"; break;
      case 5017:	e = "A text file must be for string arrays, for other arrays - binary"; break;
      case 5018:	e = "This is not a file, this is a directory"; break;
      case 5019:	e = "File does not exist"; break;
      case 5020:	e = "File can not be rewritten"; break;
      case 5021:	e = "Wrong directory name"; break;
      case 5022:	e = "Directory does not exist"; break;
      case 5023:	e = "This is a file, not a directory"; break;
      case 5024:	e = "The directory cannot be removed"; break;
      
      // String Casting
      case 5030:	e = "No date in the string"; break;
      case 5031:	e = "Wrong date in the string"; break;
      case 5032:	e = "Wrong time in the string"; break;
      case 5033:	e = "Error converting string to date"; break;
      case 5034:	e = "Not enough memory for the string"; break;
      case 5035:	e = "The string length is less than expected"; break;
      case 5036:	e = "Too large number, more than ULONG_MAX"; break;
      case 5037:	e = "Invalid format string"; break;
      case 5038:	e = "Amount of format specifiers more than the parameters"; break;
      case 5039:	e = "Amount of parameters more than the format specifiers"; break;
      case 5040:	e = "Damaged parameter of string type"; break;
      case 5041:	e = "Position outside the string"; break;
      case 5042:	e = "0 added to the string end, a useless operation"; break;
      case 5043:	e = "Unknown data type when converting to a string"; break;
      case 5044:	e = "Damaged string object"; break;
      
      // Operations with Arrays
      case 5050:	e = "Copying incompatible arrays. String array can be copied only to a string array, and a numeric array - in numeric array only"; break;
      case 5051:	e = "The receiving array is declared as AS_SERIES, and it is of insufficient size"; break;
      case 5052:	e = "Too small array, the starting position is outside the array"; break;
      case 5053:	e =  "An array of zero length"; break;
      case 5054:	e =  "Must be a numeric array"; break;
      case 5055:	e =  "Must be a one-dimensional array"; break;
      case 5056:	e =  "Timeseries cannot be used"; break;
      case 5057:	e =  "Must be an array of type double"; break;
      case 5058:	e =  "Must be an array of type float"; break;
      case 5059:	e =  "Must be an array of type long"; break;
      case 5060:	e =  "Must be an array of type int"; break;
      case 5061:	e =  "Must be an array of type short"; break;
      case 5062:	e =  "Must be an array of type char"; break;
   }
   
   e = e + " (" + DoubleToString(code,0) + ")";
   
   return e;
}