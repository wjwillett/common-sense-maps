package etc
{
	public class AirQualityColors
	{
		
		/**
		 * EPA-specified AQI Levels 
		 */		
		public static const GOOD:String = "Good";
		public static const MODERATE:String = "Moderate";
		public static const UNHEALTHY_SENSITIVE:String = "Unhealthy for Sensitive Groups";
		public static const UNHEALTHY:String = "Unhealthy";
		public static const VERY_UNHEALTHY:String = "Very Unhealthy";
		public static const HAZARDOUS:String = "Hazardous";
		
		/**
		 * EPA-specified AQI Color Codes 
		 */		
		public static const GOOD_COLOR:uint = 0x00E400;
		public static const MODERATE_COLOR:uint = 0xFFFF00;
		public static const UNHEALTHY_SENSITIVE_COLOR:uint = 0xFF7E00;
		public static const UNHEALTHY_COLOR:uint = 0xFF0000;
		public static const VERY_UNHEALTHY_COLOR:uint = 0x99004C;
		public static const HAZARDOUS_COLOR:uint = 0x4C0026;
		
		
		/**
		 * Pollutant types  
		 */		
		public static const OZONE_8HR:String = "ozone8"; 	//Ozone (8-hour)
		public static const OZONE_1HR:String = "ozone1"; 	//Ozone (1-hour)
		public static const PM_25_24HR:String = "pm25";		//Particulate Matter 2.5 (24-hour) 
		public static const PM_10_24HR:String = "pm10";		//Particulate Matter 10 (24-hour)
		public static const CO_8HR:String = "co";			//Carbon Monoxide (8-hour)
		public static const SO2_24HR:String = "so2";		//Sulfur Dioxide (24-hour)
		
		
		/**
		 * EPA-specified AQI thresholds for pollutants 
		 */		
		public static const POLLUTANT_INDEX:Object = {
			//pollutant:[good, moderate, sensitive, unhealthy, very, hazardous]
			
			//Ozone (8-hour) ppm
			ozone8 : [0,	0.06,	0.076,	0.096,	0.116,	0.405],
			
			//Ozone (1-hour) ppm
			ozone1 : [0.125,0.125,	0.125,	0.165,	0.195,	0.405],
			
			//Particulate Matter 2.5 (24-hour) milligrams / m^3
			pm25   : [0,	0.015,	0.040,	0.065,	0.150,	0.250],
			//Particulate Matter 2.5 (24-hour) micrograms / m^3
			//pm25   : [0,	15,		40,		65,		150,	250],
			
			//Particulate Matter 10 (24-hour) micrograms / m^3
			pm10   : [0,	50,		150,	250,	350,	420],
			
			//Carbon Monoxide (8-hour) ppm
			co     : [0,	4,		9,		12,		15,		30],
			
			//Sulfur Dioxide (24-hour) ppm
			so2    : [0,	0.03,	0.14,	0.22,	0.3,	0.6],
			
			//AQI (corresponding indices for above breakpoints)
			aqi    : [0,	51,		101,	151,	201,	301]
		};
		
		protected static const AQI_CAT_TO_COLOR_LOOKUP:Object = {
			"Good":GOOD_COLOR,
			"Moderate":MODERATE_COLOR,
			"Unhealthy for Sensitive Groups":UNHEALTHY_SENSITIVE_COLOR,
			"Unhealthy":UNHEALTHY_COLOR,
			"Very Unhealthy":VERY_UNHEALTHY_COLOR,
			"Hazardous":HAZARDOUS_COLOR
		};
		
		
		public static function getColorForAQICategory(level:String):uint{
			try{ return AQI_CAT_TO_COLOR_LOOKUP[level]; }
			catch(e:Error){}
			return 0x333333; //default to grey
		}

		
		public static function getColorForValue(pollutant:String,value:Number):uint{
			return getColorForAQICategory(getAQICategoryForValue(pollutant,value));
		}

		
		public static function getAQICategoryForValue(pollutant:String, value:Number):String{
			if(value >= POLLUTANT_INDEX[pollutant][0] && value < POLLUTANT_INDEX[pollutant][1]) return GOOD;
			else if(value >= POLLUTANT_INDEX[pollutant][1] && value < POLLUTANT_INDEX[pollutant][2]) return MODERATE;
			else if(value >= POLLUTANT_INDEX[pollutant][2] && value < POLLUTANT_INDEX[pollutant][3]) return UNHEALTHY_SENSITIVE;
			else if(value >= POLLUTANT_INDEX[pollutant][3] && value < POLLUTANT_INDEX[pollutant][4]) return UNHEALTHY;
			else if(value >= POLLUTANT_INDEX[pollutant][4] && value < POLLUTANT_INDEX[pollutant][5]) return VERY_UNHEALTHY;
			else if(value >= POLLUTANT_INDEX[pollutant][5]) return HAZARDOUS;
			else return 'null';
		}
		
		public static function getAQIValueForValue(pollutant:String, value:Number):Number{
			var C_p:Number = value;
			var I_p:Number;
			var I_Hi:Number;
			var I_Lo:Number;
			var BP_Hi:Number;
			var BP_Lo:Number;
			
			if(value >= POLLUTANT_INDEX[pollutant][0] && value < POLLUTANT_INDEX[pollutant][1]){
				BP_Lo = POLLUTANT_INDEX[pollutant][0];
				BP_Hi = POLLUTANT_INDEX[pollutant][1];
				I_Lo = POLLUTANT_INDEX["aqi"][0];
				I_Hi = POLLUTANT_INDEX["aqi"][1];
			}
			else if(value >= POLLUTANT_INDEX[pollutant][1] && value < POLLUTANT_INDEX[pollutant][2]){
				BP_Lo = POLLUTANT_INDEX[pollutant][1];
				BP_Hi = POLLUTANT_INDEX[pollutant][2];
				I_Lo = POLLUTANT_INDEX["aqi"][1];
				I_Hi = POLLUTANT_INDEX["aqi"][2];
			}
				
			else if(value >= POLLUTANT_INDEX[pollutant][2] && value < POLLUTANT_INDEX[pollutant][3]){
				BP_Lo = POLLUTANT_INDEX[pollutant][2];
				BP_Hi = POLLUTANT_INDEX[pollutant][3];
				I_Lo = POLLUTANT_INDEX["aqi"][2];
				I_Hi = POLLUTANT_INDEX["aqi"][3];
			}
				
			else if(value >= POLLUTANT_INDEX[pollutant][3] && value < POLLUTANT_INDEX[pollutant][4]){
				BP_Lo = POLLUTANT_INDEX[pollutant][3];
				BP_Hi = POLLUTANT_INDEX[pollutant][4];
				I_Lo = POLLUTANT_INDEX["aqi"][3];
				I_Hi = POLLUTANT_INDEX["aqi"][4];				
			}
				
			else if(value >= POLLUTANT_INDEX[pollutant][4] && value < POLLUTANT_INDEX[pollutant][5]){
				BP_Lo = POLLUTANT_INDEX[pollutant][4];
				BP_Hi = POLLUTANT_INDEX[pollutant][5];
				I_Lo = POLLUTANT_INDEX["aqi"][4];
				I_Hi = POLLUTANT_INDEX["aqi"][5];			
			}
				
			else if(value >= POLLUTANT_INDEX[pollutant][5]){
				BP_Lo = POLLUTANT_INDEX[pollutant][4];
				BP_Hi = POLLUTANT_INDEX[pollutant][5];
				I_Lo = POLLUTANT_INDEX["aqi"][4];
				I_Hi = POLLUTANT_INDEX["aqi"][5];	
			}
			else
				return -1;
			
			I_p = ((I_Hi - I_Lo)/(BP_Hi - BP_Lo))*(C_p - BP_Lo) + I_Lo;
			
			return I_p;
		}
	}
}