//+------------------------------------------------------------------+
//| RSI Dashboard.mq4
//| Copyright © 2016, Jackie Griffin
//+------------------------------------------------------------------+

#property copyright "Copyright © 2016, Jackie Griffin"
#define version "1.01"

/* Dashboard to display current RSI values in different timeframes
   for chosen pairs
*/

/* 1.0 Adding barsback
 * 1.01 Fixed initialization
*/

#property indicator_chart_window

extern string	DisplayPairs = "EURUSD,EURJPY,EURCAD,EURNZD,EURAUD,GBPCHF,GBPAUD,GBPJPY,GBPCAD,GBPNZD,GBPUSD,AUDUSD,AUDCAD,AUDJPY,AUDNZD,NZDUSD,USDCAD,USDCHF,USDJPY,USDMXN";
extern string	DisplayPeriods = "M1,M5,M15,H1,H4,D1,W1,MN";
extern int     BarsBackForOBOS=10;
extern int     RSILen=28;
extern int     RSIOB=70;
extern int     RSIOS=30;
extern int		FontSize=14;
extern color	FontColour=DarkTurquoise;
extern string	KDFont = "Arial";
extern double	DisplayStarts_X=30; 	
extern double	DisplayStarts_Y=20;  
extern int     YDistance=30;
extern int     XDistance=60;


int		PairCount;				// Number of pairs in matrix
int		PeriodCount;			// Number of periods per pair
string   Pairs[];
string   Periods[];
int      DisplayCorner=0;

struct SQUARE 
{
   string symbol;
   string periodstr;
   int period;
   double rsivalue;
   color txtcolor;
   bool ob;
   bool os;
};

SQUARE Elements[];

string objPrefix="RSIElement" ;	// object names contain this

//+------------------------------------------------------------------+
void OnInit()
//+------------------------------------------------------------------+
{
   // Size arrays based on user provided symbol and period lists
   PairCount = StringSplit(DisplayPairs,StringGetCharacter(",",0),Pairs);
   ArrayResize(Pairs, PairCount);
   
	PeriodCount = StringSplit(DisplayPeriods,StringGetCharacter(",",0),Periods);
	ArrayResize(Periods, PeriodCount);

	ArrayResize(Elements, (PairCount*PeriodCount));
	
}// End init()

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
//+------------------------------------------------------------------+
{
//----
	removeObjects(objPrefix);
}

void OnTimer() {

}

//+------------------------------------------------------------------+
int start()
{
   fillElements();
   printMatrix();
   return(0);
}

//-------------------------------------------------------------------+
int removeObjects(string Pref)
//+------------------------------------------------------------------+
{   
	int i;
	string objname = "";

	for (i = ObjectsTotal(); i >= 0; i--)
	{
		objname = ObjectName(i);
		if (StringFind(objname, Pref, 0) > -1) ObjectDelete(objname);
	}
	return(0);
} 

int periodFix(string str)
//+------------------------------------------------------------------+
{
  if (str == "M1")   return(1);
  if (str == "M5")   return(5);
  if (str == "M15")  return(15);
  if (str == "M30")  return(30);
  if (str == "H1")   return(60);
  if (str == "H4")   return(240);
  if (str == "D1")   return(1440);
  if (str == "W1")   return(10080);
  if (str == "MN")   return(43200);
  return(0);
} 

/*int countFilters()
{
   int count=1;  // always include KD
   
   if (RSIFilter) count++;
   
   return(count);
} 
*/
//+------------------------------------------------------------------+
int fillElements()
//+------------------------------------------------------------------+
{
	int i, j, k, tmpbars=0;
	double rsivalue;
	
	k=0;
	for (i=0; i<PairCount; i++) {
	   for (j=0; j<PeriodCount; j++) {
         Elements[k].symbol = Pairs[i];
	      Elements[k].periodstr = Periods[j];
	      Elements[k].period = periodFix(Periods[j]);
	      
	      rsivalue=iRSI(Elements[k].symbol, Elements[k].period, RSILen, PRICE_CLOSE, 0);
	      Elements[k].rsivalue=NormalizeDouble(rsivalue, 2);
         checkRSIXBars(Elements[k].symbol, Elements[k].period, k);
	      if (Elements[k].os) {
	         Elements[k].txtcolor=clrLime;
	      } else if (Elements[k].ob) {
	         Elements[k].txtcolor=clrRed;
	      } else {
	         Elements[k].txtcolor=clrWhite;
	      }
	      k++;
	   }
	}
	return(0);
}			

//+------------------------------------------------------------------+
int printMatrix()
//+------------------------------------------------------------------+
{
	
	int i, j, k;
	string tmprsi;
	color tmpcolor;
	int xPos=0, yPos=0;
	string buff_str;
	
	
	removeObjects(objPrefix);
	
	// Display labels
	for(i=0; i<PairCount; i++)
	{
	   xPos=DisplayStarts_X;
	   yPos=DisplayStarts_Y + ((i+1)*YDistance); 
		buff_str = StringConcatenate(objPrefix, Pairs[i]);
		drawText( buff_str, Pairs[i], xPos, yPos, FontColour, FontSize, KDFont);  
   }
	for(j=0; j<PeriodCount; j++)
	{
	   xPos=DisplayStarts_X+((j+2)*XDistance);
	   yPos=DisplayStarts_Y;
	   
		buff_str = StringConcatenate(objPrefix, Periods[j]);
		drawText( buff_str, Periods[j], xPos, yPos, FontColour, FontSize, KDFont);
	}

   k=0;
	for(i=0; i<PairCount; i++)
	{
		for(j=0; j<PeriodCount; j++)
		{
			buff_str = StringConcatenate(objPrefix, Pairs[i], Periods[j]);
			xPos=DisplayStarts_X+((j+2)*XDistance);
			yPos=DisplayStarts_Y + ((i+1)*YDistance);
			tmprsi=IntegerToString(Elements[k].rsivalue);
			tmpcolor=Elements[k].txtcolor;
			drawText( buff_str, tmprsi, xPos, yPos, tmpcolor, FontSize, KDFont); 
 
			k++;
      }
   }
			
	return(0);
}

//+------------------------------------------------------------------+
//| Create text object                                               |
//+------------------------------------------------------------------+
void drawText( string elementName, string eText, double xPos, double yPos, color eColor, int eFontSize, string eFont) {

   int windowNum=0;
   
   ObjectDelete( elementName);
   ObjectCreate( elementName, OBJ_LABEL, windowNum, 0, 0);
   ObjectSetText( elementName, eText, eFontSize, eFont, eColor);
   ObjectSet( elementName, OBJPROP_XDISTANCE, xPos );
   ObjectSet( elementName, OBJPROP_YDISTANCE, yPos );
   ObjectSet( elementName, OBJPROP_BACK, false);
}


void checkRSIXBars(string sym, int per, int j) {

   int i=0;
   double rsivalue=0;
   
   Elements[j].os=false;
   Elements[j].ob=false;
   while (i<BarsBackForOBOS) {
   
         rsivalue=iRSI(sym, per, RSILen, PRICE_CLOSE, i);
         if (rsivalue <= RSIOS)
         {
            Elements[j].os=true;
            break;
         } else if (rsivalue >= RSIOB)
         {
            Elements[j].ob=true;
            break;
         } 
         i++;
   }
}

//+------------------------------------------------------------------+

