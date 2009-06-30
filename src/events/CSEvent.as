package events
{
	import flash.display.Sprite;
	import flash.events.Event;

	public class CSEvent extends Event
	{
		
		public static const COMMENT_MARKER_ADDED:String = "commentMarkerAdded";
		public static const PAN_AND_ZOOM_COMPLETE:String = "panAndZoomComplete";
		public static const REMOVE_CLICKED:String = "removeClicked";
		
		protected var marker:Sprite;
		
		public function CSEvent(type:String, marker:Sprite=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.marker = marker; 
		}
		
	}
}