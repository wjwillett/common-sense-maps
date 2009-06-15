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
			
			var mData:Object = markers.data;
			var createdMarkers:Array = [];
			for each(var d:Object in mData){
				createdMarkers.push(new FlagMarker(new Location(d.latitude,d.longitude),d.zoom,d.id));
			} 
			return createdMarkers;
		}
		
		
	}
}