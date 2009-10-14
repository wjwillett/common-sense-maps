package data
{
	import __AS3__.vec.Vector;
	
	public class Stats
	{
		private var spikeEpisodes:Array;
		//private var topTenEpisodes:Array; // for internal debugging if required
		private var episodeEndTimes:Object;
		private var windowStaggering:Number = 30; // hard coded start time staggering for windows.
		private var myExposureAverage:Number;
		
		public function Stats(_data:Vector.<Object>, headers:Array){ // Constructor
			spikeEpisodes = new Array();
			episodeEndTimes = new Object();
			//topTenEpisodes = new Array();
			processSpikes(_data, headers);
			calculateAverage(_data, headers);
		}
		
		private function processSpikes(_data:Vector.<Object>, headers:Array):void{
			// Header indices for data array refer to PM data at the moment - standard for this may needed to be generalized
			// for different kinds of data
			var startTime:Number = 0;
			var endTime:Number = 0;
			var timeWindow:Number = 60;
			var windowAverage:Number = 0;
			var windowCounter:Number = 0;
			var startPos:Number = 0;
			var i:Number = 0;
			var k:Number = 0;
			
			while(true){ 
				startTime = Number(_data[startPos][headers[0]]);
				
				windowCounter = 0;
				windowAverage = 0;
				
				k = startPos;
				// check a 60-second window of data
				while(k < _data.length && _data[k][headers[0]] < startTime+60){ // 1-minute time window
					windowAverage += Number(_data[k][headers[3]])
					windowCounter++;
					endTime = _data[k][headers[0]]
					k++;
				}
				windowAverage = windowAverage/windowCounter;
				spikeEpisodes.push({'beginTime':startTime, 'endTime':endTime, 'windowAverage':windowAverage});
				// Populate the endTimes hashtable
				episodeEndTimes[endTime] = windowAverage;
				//trace("found episode: ("+startTime+","+(startTime+60)+")");
				//trace("episode end time for "+endTime+ ": "+episodeEndTimes[endTime]);
				
				i = startPos;
				// Determine the next startPos - if end of array before next window, we break
				// EDIT WINDOW HERE!
				while(i < _data.length && _data[i][headers[0]] < startTime+windowStaggering){
					i++;
				}
				if(i >= _data.length){
					break;
				}
				else{
					startPos = i;
				}
			}
			spikeEpisodes = spikeEpisodes.sortOn('windowAverage');
			// Debugging stuff
			/*
			trace("new stuff");
			for(i=0; i < spikeEpisodes.length; i++){
				trace("average of this window = "+spikeEpisodes[i]['windowAverage']);
			}
			for(i=spikeEpisodes.length-1; i > spikeEpisodes.length - 10; i--){
				topTenEpisodes.push(spikeEpisodes[i]);
			}
			// temp reassign for debugging
			spikeEpisodes = topTenEpisodes;
			for(i=0; i < spikeEpisodes.length-1; i++){
				trace("top episode: "+spikeEpisodes[i]['windowAverage']);
			}
			*/
		}
		
		public function calculateAverage(_data:Vector.<Object>, headers:Array):void{
			trace("data length="+_data.length);
			var sum:Number = 0;
			
			for(var i:Number = 0; i < _data.length; i++){
				sum += Number(_data[i][headers[3]]);
			}
			trace("sum="+sum);
			myExposureAverage = sum / _data.length;
			trace("myExposure = "+myExposureAverage);
		}
		
		public function calculateAverageAQI(average:Number):void{
			// Calculation specific to PM data for now
			
		}
		
		public function getSpikes():Array{
			return spikeEpisodes;
		}
		
		public function getEpisodeEndTimes():Object{
			return episodeEndTimes;
		}
		
		public function getMyExposureAverage():Number{
			return myExposureAverage;
		}
	}
}