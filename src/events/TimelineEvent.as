package events
{
	import flash.events.Event;

	public class TimelineEvent extends Event
	{
		
		public static const PLAYHEAD_MOVED:String = "playheadMoved";
		
		public var playheadTime:Number;
		
		public function TimelineEvent(type:String, playheadTime:Number, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.playheadTime = playheadTime;
			super(type, bubbles, cancelable);
		}
		
		
		
	}
}