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
		public function get sourceObject():Object{return _sourceObject;}
		public function get dataURI():String{return _sourceObject.toString();} 
		
		public var hidden:Boolean = false;
		
		// Added to implement hotspots filtering
		public var limitCO:Boolean = false;
		public var minCOLevel:Number = 0.0;
		public var maxCOLevel:Number = 0.0;
		
		// Added to implement spike episodes storage
		public var stats:Stats
		
		protected var multipleSources:Boolean = false;
		protected var numSourcesLoading:int = 0;
		
		/****************************** Data Loading Methods ************************************/
		protected function loadData(source:Object):void{
			//clear any old data
			_data = new Vector.<Object>();
			
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
			//if multiple sources are passed, handle each
			else if(source is Array){
				numSourcesLoading += ((source as Array).length + (multipleSources ? - 1 : 0));
				multipleSources = true;
				for each(var s:Object in source) loadData(s);
			}
			else throw new ArgumentError("Invalid data source. Source should either " + 
					"be the URI of a text file containing data or a Class containing " + 
					"an embedded text file.");
		}
		
		
		//helper method for processing loaded CSV data.
		protected function processLoaded(result:String):void{
			var entries:Array = result.split(/\r|\n/gi);
			
			if(entries.length > 1){
				var headers:Array = (entries[0] as String).split(',');
				
				for(var i:int = 1; i < entries.length; i++){
					var entry:Array = (entries[i] as String).split(',');
					if(headers.length != entry.length && i < entries.length - 1){
						throw new Error("Row " + i + ":(" + entries[i] + ") from data source \"" + 
							dataURI + "\" has a different number of elements than the header row:(" +
							entries[0] + ").");  
					} 
					// Check if CO Level is limited (for hotspots view specifically)
					if(limitCO == true && (entry[5] < minCOLevel || entry[5] > maxCOLevel))
						continue;
					else{
						var pointData:Object = {}
						for(var h:int=0;h < headers.length;h++) pointData[headers[h]] = entry[h];
						//annotate the point with a reference to its source
						pointData.sourceURI = dataURI;
						_data.push(pointData);
					}
				}
			}
			
			//sort and dispatch a complete event if were done loading everything
			if(multipleSources) numSourcesLoading--;
			if(!multipleSources || numSourcesLoading == 0){
				_data.sort(function(x:Object, y:Object):Number{
						return Number(x.time) - Number(y.time);
					});
				// execute stats object update now that data is available
				stats = new Stats(_data, headers);
				
				// Note the example below on how to iterate through spikes in the data
				/*
				var episodesArray:Array = stats.getSpikes();
				for(var k:Number = 0; k < episodesArray.length; k++){
					trace("behold the spike episodes"+"("+episodesArray[k].beginTime+", "+episodesArray[k].endTime+")");
				}
				*/
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		
		/****************************** Helper Methods ************************************/
		protected function getPointIndex(dataPoint:Object):int{
			return _data ? _data.lastIndexOf(dataPoint) : -1;
		}
	}
}