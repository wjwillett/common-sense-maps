package data
{
	import __AS3__.vec.Vector;
	
	public class Stats
	{
		private var spikeEpisodes:Array;
		
		public function Stats(_data:Vector.<Object>, headers:Array){ // Constructor
			spikeEpisodes = new Array();
			processSpikes(_data, headers);
		}
		
		private function processSpikes(_data:Vector.<Object>, headers:Array):void{
			// Header indices for data array refer to PM data at the moment - standard for this may needed to be generalized
			// for different kinds of data
			var startTime:Number = 0;
			var timeWindow:Number = 60;
			var windowAverage:Number = 0;
			var windowCounter:Number = 0;
			var k:Number = 0;
			
			for(var i:Number=0; i < _data.length; i += 30){ 
			// 30-second staggering for window checks: 
			// NOTE that this 30 refers to the array index, not actual time...
			// I probably need to change this, but PM has data for every second, so it seems ok for now...
				startTime = Number(_data[i][headers[0]]);
				k = i;
				windowCounter = 0;
				windowAverage = 0;
				
				// check a 60-second window of data
				while(k < _data.length && _data[k][headers[1]] < startTime+60){ // 1-minute time window
					windowAverage += Number(_data[k][headers[3]])
					windowCounter++;
					k++;
				}
				windowAverage = windowAverage/windowCounter;
				if(windowAverage > 0.020){ // Hard-coding the threshold of "spike-interest"
					spikeEpisodes.push({'beginTime':startTime, 'endTime':startTime+60});
					//trace("found episode: ("+startTime+","+(startTime+60)+")");
				}
			}
		}
		
		public function getSpikes():Array{
			return spikeEpisodes;
		}
	}
}