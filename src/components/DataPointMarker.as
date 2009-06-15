package components
{
	import com.modestmaps.geo.Location;
	
	import flash.display.Sprite;

	public class DataPointMarker extends Sprite
	{
		public var location:Location;
		public var value:Number;
		public var level:String;
		public var time:String;
		
		
		public const MIN_DIAMETER:Number = 5;
		public const MAX_DIAMETER:Number = 25;
		public const DIAMETER_SCALE_FACTOR:Number = 80;
		
		public function DataPointMarker(lat:Number,lon:Number,value:Number=NaN,level:String=null,time:String=null)
		{
			this.location = new Location(lat,lon);
			this.value = value;
			this.level = level;
			this.time = time;
			
			//var diameter:Number = Math.min(Math.max(value*DIAMETER_SCALE_FACTOR, MIN_DIAMETER),MAX_DIAMETER);
			var diameter:Number = MIN_DIAMETER;
			var color:uint = AirQualityColors.getColorForLevel(level);
			
			graphics.lineStyle(0.5,0xffffff,0.6);
			graphics.beginFill(color,0.6);
			graphics.drawCircle(0,0,diameter - 1);
		}
	}
}