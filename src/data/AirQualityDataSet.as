package data
{
	import __AS3__.vec.Vector;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class AirQualityDataSet extends EventDispatcher
	{
		public function AirQualityDataSet(source:Object, pollutant:String, name:String="")
		{
			_sourceObject = source;
			this.pollutant = pollutant;
			this.name = name;	
			loadData(source);
		}
		
		
		protected var _sourceObject:Object;
		protected var _data:Vector.<Object>;
			 
		public var name:String;
		public var pollutant:String;
				
		public function get data():Vector.<Object>{return _data;}
		public function get dataURI():String{return _sourceObject.toString();} 
		
		
		
		
		
		/****************************** Data Loading Methods ************************************/
		protected function loadData(source:Object):void{
			//Handle embedded data		
			if(source is Class) processLoaded(new (source as Class)());
			//Load data from the web
			else if(source is String){
				var request:URLRequest = new URLRequest(source as String);
				var loader:URLLoader = new URLLoader(request);
				loader.addEventListener(ProgressEvent.PROGRESS,function(pe:ProgressEvent):void{
						//forward progress events
						dispatchEvent(pe);					
					});
				loader.addEventListener(Event.COMPLETE,function(e:Event):void{
						if(loader.data is String) processLoaded(loader.data as String);
					});				
			}
			else throw new ArgumentError("Invalid data source. Source should either " + 
					"be the URI of a text file containing data or a Class containing " + 
					"an embedded text file.");
		}
		
		
		//helper method for processing loaded CSV data.
		protected function processLoaded(result:String):void{
			var entries:Array = result.split(/\r|\n/gi);
			
			_data = new Vector.<Object>();
			if(entries.length > 1){
				var headers:Array = (entries[0] as String).split(',');
				
				for(var i:int = 1; i < entries.length; i++){
					var entry:Array = (entries[i] as String).split(',');
					if(headers.length != entry.length && i < entries.length - 1){
						throw new Error("Row " + i + ":(" + entries[i] + ") from data source \"" + 
							dataURI + "\" has a different number of elements than the header row:(" +
							entries[0] + ").");  
					}  
					var pointData:Object = {}
					for(var h:int=0;h < headers.length;h++) pointData[headers[h]] = entry[h];
					//annotate the point with a reference to its source
					pointData.sourceURI = dataURI;
					_data.push(pointData);
				}
			}
			
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		
		/****************************** Helper Methods ************************************/
		protected function getPointIndex(dataPoint:Object):int{
			return _data ? _data.lastIndexOf(dataPoint) : -1;
		}
	}
}