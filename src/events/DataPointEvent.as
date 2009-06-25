package events
{
	import flash.events.Event;

	public class DataPointEvent extends Event
	{
		public static const HOVER:String = "hover";
		public static const UNHOVER:String = "unHover";
		
		public var dataPoint:Object;
		
		public function DataPointEvent(type:String, dataPoint:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.dataPoint = dataPoint;
			if(type == HOVER && !dataPoint) throw new ArgumentError("DataPointEvent.HOVER events must specify a data point");
		}
		
	}
}