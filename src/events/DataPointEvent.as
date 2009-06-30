package events
{
	import flash.events.Event;

	public class DataPointEvent extends Event
	{
		public static const CLICK:String = "clickDataPoint";
		public static const HOVER:String = "hoverDataPoint";
		public static const UNHOVER:String = "unHoverDataPoint";
		
		public var dataPoint:Object;
		
		public function DataPointEvent(type:String, dataPoint:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.dataPoint = dataPoint;
			if(type == HOVER && !dataPoint) throw new ArgumentError("DataPointEvent.HOVER events must specify a data point");
		}
		
	}
}