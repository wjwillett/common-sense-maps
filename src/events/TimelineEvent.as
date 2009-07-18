package events
{
	import flash.events.Event;

	public class TimelineEvent extends Event
	{
		
		public static const PLAYHEAD_MOVED:String = "playheadMoved";
		public static const PLAYHEAD_STOPPED:String = "playheadStopped";
		public static const TIMELINE_ZOOMED:String = "timelineZoomed";
		public static const TIMELINE_SCROLLED:String = "timelineScrolled";
		
		
		public var playheadTime:Number;
		
		public function TimelineEvent(type:String, playheadTime:Number, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			this.playheadTime = playheadTime;
			super(type, bubbles, cancelable);
		}
		
		
		
	}
}