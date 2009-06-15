package components
{
	public class AirQualityColors
	{
		public static const GOOD_COLOR:uint = 0x00E400;
		public static const MODERATE_COLOR:uint = 0xFFFF00;
		public static const UNHEALTHY_SENSITIVE_COLOR:uint = 0xFF7E00;
		public static const UNHEALTHY_COLOR:uint = 0xFF0000;
		public static const VERY_UNHEALTHY_COLOR:uint = 0x99004C;
		public static const HAZARDOUS_COLOR:uint = 0x4C0026;
		
		public static function getColorForLevel(level:String):uint{
			switch(level){
				case "Good": 
				case "PM Good": 
					return GOOD_COLOR;
				case "Moderate":
				case "PM Moderate":
					return MODERATE_COLOR;
				case "Unhealthy for Sensitive Groups":
				case "PM Unhealthy for Sensitive Groups":
					return UNHEALTHY_SENSITIVE_COLOR;
				case "Unhealthy":
				case "PM Unhealthy": 
					return UNHEALTHY_COLOR;
				case "Very Unhealthy":
				case "PM Very Unhealthy": 
					return VERY_UNHEALTHY_COLOR;
				case "Hazardous":
				case "PM Hazardous": 
					return HAZARDOUS_COLOR;
				default:
					return 0x333333;
			} 
		}
	}
}