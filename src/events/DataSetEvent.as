package events
{
	import data.AirQualityDataSet;
	
	import flash.events.Event;

	public class DataSetEvent extends Event
	{
		public static const DATASET_REMOVED:String = "commonSenseDataSetRemoved"; 
		public static const DATASET_HIDDEN:String = "commonSenseDataSetHidden";
		public static const DATASET_UNHIDDEN:String = "commonSenseDataSetUnhidden"; 
		
		public var dataset:AirQualityDataSet;
		
		public function DataSetEvent(type:String, dataset:AirQualityDataSet,bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.dataset = dataset;
			
		}
		
	}
}