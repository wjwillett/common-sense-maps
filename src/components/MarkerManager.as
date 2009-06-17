package components
{
	import com.modestmaps.geo.Location;
	
	import flash.net.SharedObject;

	/**
	 * Handles storing and retrieving markers (currently just FlagMarkers)
	 *  from a data store (currently just a local SharedObject)  
	 * @author willettw
	 * 
	 */
	public class MarkerManager
	{
		public function MarkerManager()
		{

		}
		
		//local marker storage
		private static const MARKERS_SHARED_OBJECT:String = "____CommonSenseMarkers____";
		protected static var markers:SharedObject = SharedObject.getLocal(MARKERS_SHARED_OBJECT);
		
		
		public static function saveMarker(m:FlagMarker):void{
			markers.data[m.id] = { zoom:m.zoom,
				latitude:m.location.lat,
				longitude:m.location.lon,
				id:m.id};
			markers.flush();
		}
		
		public static function deleteMarker(m:FlagMarker):void{
			delete markers.data[m.id];
			markers.flush();
		}
		
		public static function getMarker(id:uint):FlagMarker{
			var mData:Object = markers.data;
			if(mData[id]) return new FlagMarker(new Location(mData[id].latitude,mData[id].longitude), mData[id].zoom, id);
			else return null;
		}
		
		public static function getMarkers():Array{
			
			setupDefaultMarkers();
			
			var mData:Object = markers.data;
			var createdMarkers:Array = [];
			for each(var d:Object in mData){
				createdMarkers.push(new FlagMarker(new Location(d.latitude,d.longitude),d.zoom,d.id));
			} 
			return createdMarkers;
		}
		
		/**
		 * Debugging method that sets up new default markers on a machine without any. 
		 */		
		private static function setupDefaultMarkers():void{
			//markers.clear();
			//markers.flush();
			if(!markers.data || !markers.data[2613824377]){
				markers.data[2613824377] = {id:2613824377, latitude:37.820797824794326,longitude:-122.30297000994227,zoom:19};
				markers.data[3399561873] = {id:3399561873, latitude:37.8175336911584,longitude:-122.29114012747993,zoom:17};
				markers.data[2378204341] = {id:2378204341, latitude:37.81308705780995,longitude:-122.29769959260042,zoom:15};
				markers.flush();
			}
		}
		
		
	}
}