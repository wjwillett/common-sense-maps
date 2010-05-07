package components
{
	import __AS3__.vec.Vector;
	
	import com.modestmaps.Map;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.geo.Location;
	
	import data.AirQualityDataSet;
	import data.SelectionSet;
	
	import etc.AirQualityConstants;
	import etc.DirtyFlag;
	import etc.PointRenderer;
	import etc.AirQualityColors;
	
	import events.DataPointEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.controls.ToolTip;
	import mx.events.CollectionEvent;
	import mx.managers.ToolTipManager;
	
	import papervision3Dqtree.QuadTree;
	import papervision3Dqtree.QuadTreeItem;
	

	public class AirQualityMapLayer extends Sprite
	{
		protected var _dataSets:Vector.<AirQualityDataSet>;
		protected var _selections:SelectionSet; //the set of selections to draw in the current display 
		protected var _map:Map;
		
		// setting this.dirty = true will redraw an MapEvent.RENDERED
		protected var dirty:DirtyFlag = new DirtyFlag;
    	protected var drawCoord:Coordinate; 
		protected var bitmap:Bitmap = new Bitmap();
		protected var plotBitmapData:BitmapData;
		protected var _plotCount:uint = 0;
		protected var _cachedBitmapData:Object = {};
		protected var _quadTree:QuadTree = new QuadTree(360,180,8);
		
		protected var _minTime:Number;				//earliest time for which points are displayed 
		protected var _maxTime:Number; 				//latest time for which points are displayed (typically paired with the playhead)
		
		protected var _prevMaxPtNums:Object = {}; 	//last point number drawn by the last append pass (indexed by dataURI)
		protected var _prevPos:Object = {} 			//position of the last point drawn (indexed by dataURI)
		protected var _prevVal:Object = {}			//value of the last point drawn (indexed by dataURI)
		
		protected function get map():Map{ return _map;}
		
		public var pointOverlapTolerance:Number = 11;
		//public var pointValueTolerance:Number; // This might be needed to deal with seeing-spikes problem
		public var zoomTolerance:Number = 5; 
		public var pointDiameter:Number = 15;
		public var numMouseOverAdjacents:uint = 15;
		
		protected var _yMin:Number;			//the lowest data value on the y axis
		protected var _yMax:Number; 		//the highest data value on the y axis
		protected var _yMinManual:Number = NaN; //a manually specified lower y bound
		protected var _yMaxManual:Number = NaN; //a manually specified upper y bound
		
		public function get yMin():Number { return isNaN(_yMinManual) ? _yMin : _yMinManual; }
		public function set yMin(val:Number):void{_yMinManual = val; dirty.dirty();}
		public function get yMax():Number { return isNaN(_yMaxManual) ? _yMax : _yMaxManual; }
		public function set yMax(val:Number):void{_yMaxManual = val; dirty.dirty();}
		
		public function clearLimits():void{
			yMin = NaN;
			yMax = NaN;
			
			dirty.dirty();
		}
		
		
		/**
		 * A set of objects that contain lists of datapoints, along with
		 *  names, uris, and pollutants for each. 
		 * @param d
		 * @param AirQualityDataSet
		 * 
		 */		
		public function set dataSets(d:Vector.<AirQualityDataSet>):void{
			_dataSets = d;
			for each(var ds:AirQualityDataSet in d){
				addToQuadTree(ds);
			}
			dirty.dirty();
			plotData();
		}
		public function get dataSets():Vector.<AirQualityDataSet>{
			return _dataSets;
		}
		
		/**
		 * A set of selections to draw.
	 	 */		
		public function get selections():SelectionSet{ return _selections;}
		public function set selections(s:SelectionSet):void{
			_selections = s;
			s.addEventListener(CollectionEvent.COLLECTION_CHANGE, function(ce:CollectionEvent):void{
					dirty.dirty();
					refresh();									
				});
		}	
		
		
		public function set minTime(m:Number):void{
			if(m == _minTime) return;
			dirty.dirty(DirtyFlag.DIRTY);  	//Changing minTime always needs a full redraw
			_minTime = m;
		}
		public function get minTime():Number{
			return !isNaN(_minTime) ? _minTime : NaN;
		}
		
		
		public function set maxTime(m:Number):void{
			if(m == _maxTime) return;
			if(m < _maxTime || isNaN(_maxTime))dirty.dirty(DirtyFlag.DIRTY);  	//If backtracking, need a full redraw
			else dirty.dirty(DirtyFlag.APPEND);				//If moving forward, can append
			_maxTime = m;
		}
		public function get maxTime():Number{
			return !isNaN(_maxTime) ? _maxTime : NaN;
		}
		
		
		public function AirQualityMapLayer(map:Map,dataSets:Vector.<AirQualityDataSet> = null)
		{
			super();
			
			this.mouseEnabled = false;
			
			this._map = map;
			this.addChild(bitmap);
			this.dataSets = dataSets;
			
			map.addEventListener(MapEvent.START_ZOOMING, onMapStartZooming);
	        map.addEventListener(MapEvent.STOP_ZOOMING, onMapStopZooming);
	        map.addEventListener(MapEvent.ZOOMED_BY, onMapZoomedBy);
	        map.addEventListener(MapEvent.START_PANNING, onMapStartPanning);
	        map.addEventListener(MapEvent.STOP_PANNING, onMapStopPanning);
	        map.addEventListener(MapEvent.PANNED, onMapPanned);
	        map.addEventListener(MapEvent.RESIZED, onMapResized);
	        map.addEventListener(MapEvent.EXTENT_CHANGED, onMapExtentChanged);
	        map.addEventListener(MapEvent.RENDERED, plotData);
	       
	        map.addEventListener(MouseEvent.ROLL_OVER, handleMouseMove);
	        map.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
	        map.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
	        map.addEventListener(MouseEvent.CLICK, handleMouseClick);
	        
		}
		
		public function refresh(force:Boolean=false):void{
			if(force){
				 _quadTree.clearItems();
				 for each(var ds:AirQualityDataSet in _dataSets) addToQuadTree(ds);
				 dirty.dirty();
			}
			plotData();
		}
		
		
		protected function addToQuadTree(dataSet:AirQualityDataSet):void{
			for each(var dp:Object in dataSet.data){
				if(!(dp.lat || dp.lon) || dp.lat == 'None' || dp.lon == 'None') continue;
				var dpr:Rectangle = new Rectangle(Number(dp.lon) + 180,Number(dp.lat) + 90,0,0)
				var dpq:QuadTreeItem = new QuadTreeItem(dp,dpr);
				_quadTree.insertItem(dpq);
			}
		}

		
		protected function plotData(e:Event=null):void{
			
			//don't redraw if clean
			if(dirty.check(DirtyFlag.CLEAN))return;
	    	
	    	drawCoord = map.grid.centerCoordinate.copy();
			
			//Centers this clip over the map
	    	this.x = map.getWidth() / 2;
	    	this.y = map.getHeight() / 2;	    	
	        scaleX = scaleY = 1.0;
			
			//Set up the bitmapData we'll paint into
			//TODO: This will break for displays bigger than 2800px.
			var w:Number = Math.min(2880, 2*map.getWidth());
        	var h:Number = Math.min(2880, 2*map.getHeight());
			
			//only build a new bitmap data if actually dirty (appends reuse the old bitmapdata)
			if(dirty.check() || !plotBitmapData){ 
				if(!plotBitmapData || plotBitmapData.width != w || plotBitmapData.height != h) {
		        	if (plotBitmapData) {
		        		plotBitmapData.dispose();
		        	}
		            plotBitmapData = new BitmapData(w,h,true,0x00000000);
					bitmap.bitmapData = plotBitmapData;
		            bitmap.x = -w/2;
		            bitmap.y = -h/2;
		        }
		        else {
		            plotBitmapData.fillRect(new Rectangle(0,0,plotBitmapData.width,plotBitmapData.height),0x00000000);
		        }
		        _prevPos = {};
		        _prevVal = {};
			}
	        
			//prep the renderer we'll use to draw points
			var renderer:PointRenderer = new PointRenderer(plotBitmapData,pointDiameter,pointOverlapTolerance);
			
			
			plotBitmapData.lock();
			
			//for each of the sets of points...
			for each(var ds:AirQualityDataSet in _dataSets){
				//iterate through recorded points
				
				//don't draw if data is missing or hidden 
				if(!ds.data || ds.hidden) continue;
				
				//start from the last drawn point if possible
				var firstPoint:int = (dirty.check(DirtyFlag.APPEND) && _prevMaxPtNums[ds.dataURI]) ?  _prevMaxPtNums[ds.dataURI] : 0;
				
				for(var i:int=firstPoint; i < ds.data.length; i++){
					var point:Object = ds.data[i]; 
				
					//don't plot points without GPS data
					if(!point.lat || point.lat == "None") continue;
					
					//don't plot points before the mintime 
					if(!isNaN(minTime) && point.time < minTime)continue;
					//and finish drawing once we've hit the max time
					if(!isNaN(maxTime) && point.time > maxTime)break; 
					
					//determine location
					var dLoc:Location = new Location(point.lat,point.lon);
					var dPt:Point = _map.locationPoint(dLoc);
					dPt.x += (w - map.getWidth()) / 2;
					dPt.y += (h - map.getHeight()) / 2;
		
					//skip if position not different different from last plotted point
					if(!selections.isSelected(point) && _prevPos[ds.dataURI]
							&& Math.abs(_prevPos[ds.dataURI].x - dPt.x) < pointOverlapTolerance 
							&& Math.abs(_prevPos[ds.dataURI].y - dPt.y) < pointOverlapTolerance
							&& !(point.value > AirQualityColors.POLLUTANT_INDEX[ds.pollutant][2])){ 
							// could add a && _prevVal[ds.dataURI] == point.value here as additional check to see if previous value is sufficiently different
							// for now we deal with the "making spikes obvious" problem by just showing anything that looks red or worse.
						continue;
					}
					
					// Added to skip this point based off of air quality slider state
					if(!(isNaN(this.yMin) || isNaN(this.yMax))){
						if(!(point.value >= this.yMin && point.value <= this.yMax)){
							continue;
						}
					}
		
					//plot the point to the current bitmapdata
					renderer.plotPoint(point,dPt,ds.pollutant,selections.isSelected(point));
					_prevPos[ds.dataURI] = dPt;
					_prevVal[ds.dataURI] = point.value;
				}
				_prevMaxPtNums[ds.dataURI] = Math.max(i - 1,0);
			}
			
			plotBitmapData.unlock();
			
			dirty.clean();
		}
		
		
		protected function onMapExtentChanged(event:MapEvent):void
	    {
			dirty.dirty();	    	
	    }
	    
	    protected function onMapPanned(event:MapEvent):void
	    {
	    	if (drawCoord) {
		        var p:Point = map.grid.coordinatePoint(drawCoord);
		        if(_plotTip){
		        	_plotTip.x -= (this.x - p.x);
		        	_plotTip.y -= (this.y - p.y);
		        }
		        this.x = p.x;
	    	    this.y = p.y;
	    	}
	    	else {	
	    		if(stage) stage.invalidate();
	    		dirty.dirty();
	    	}
	    }
	    
	    protected function onMapZoomedBy(event:MapEvent):void
	    {
	    	cacheAsBitmap = false;
	        if (drawCoord) {
	        	if (Math.abs(map.grid.zoomLevel - drawCoord.zoom) < zoomTolerance) {
		        	scaleX = scaleY = Math.pow(2, map.grid.zoomLevel - drawCoord.zoom);
		     	}
		     	else {
		     		dirty.dirty();	
		     	}
	        }
	        else { 
		        dirty.dirty();
	        }
	    }
	
	    protected function onMapStartPanning(event:MapEvent):void
	    {
	    	// optimistically, we set this to true in case we're just moving
		    cacheAsBitmap = true;
	    }
	    
	    protected function onMapStartZooming(event:MapEvent):void
	    {
	    	// overrule onMapStartPanning if there's scaling involved
	        cacheAsBitmap = false;
	    }
	    
	    protected function onMapStopPanning(event:MapEvent):void
	    {
	    	// tidy up
	    	cacheAsBitmap = false;
	    	if(stage) stage.invalidate();
		    dirty.dirty();
	    }
	    
	    protected function onMapStopZooming(event:MapEvent):void
	    {
	        dirty.dirty();
	        _prevMaxPtNums = {};
	    }
	    
	    protected function onMapResized(event:MapEvent):void
	    {
	        x = map.getWidth() / 2;
	        y = map.getHeight() / 2;
	        if(stage) stage.invalidate();
	        dirty.dirty();
	        _prevMaxPtNums = {};
	        plotData(); // force redraw because flash seems stingy about it
	    }
	    
		/****************************** Tooltipping Methods ************************************/
		protected var _plotTip:ToolTip;
			
		/**
		 * Draws and positions a tooltip for the given datapoint.
		 */
		public function drawDataTip(dataPoint:Object):void{
			
			//Determine position and only plot if we have a real GPS location.
			if(dataPoint.lat == "None" || dataPoint.lon == "None"){
				discardActiveDataTip();
				return;
			}
			var ptPosition:Point = map.locationPoint(new Location(dataPoint.lat,dataPoint.lon),map.stage); 
			
			if(!_plotTip)_plotTip = ToolTipManager.createToolTip(dataPoint.value,ptPosition.x,ptPosition.y) as ToolTip;
		
			//color the tip and add additional text if possible
			if(dataPoint.value){
				
				//FIXME: Currently defaulting to pollutant from the first dataset, should be able to support per-track
				var pollutant:String = dataSets[0].pollutant;
				var multiplier:Number = dataSets[0].multiplier;
					
				var cat:String = AirQualityConstants.getAQICategoryForValue(pollutant,dataPoint.value);
				var color:uint = AirQualityConstants.getColorForAQICategory(cat);
				var pollutantUnits:String = AirQualityConstants.POLLUTANT_UNITS[pollutant];
				
				_plotTip.setStyle("backgroundColor",color);
				_plotTip.setStyle("backgroundAlpha",0.7);
				var time:Number = Number(dataPoint.time * 1000);
				var date:Date = new Date(time);
				var value:Number = Number(dataPoint.value / multiplier); // scaled down for the tooltip
				var badgeName:String = dataPoint.badge_id ? 'Badge ' + parseInt(dataPoint.badge_id,16).toString() : 'Unknown Badge';
				_plotTip.text = date.toLocaleDateString() + "\n" +
					date.toLocaleTimeString() + "\n" + value.toPrecision(5) + 
					" " + pollutantUnits + 
					" (" + cat + ")" + "\n" +
					"[" + badgeName + "]";
				_plotTip.x = ptPosition.x;
				_plotTip.y = ptPosition.y;
				
				_plotTip.graphics.clear();
					
				//Overplot nearby points as part of the tooltip
				/*for each(var ds:AirQualityDataSet in dataSets){
					var pn:int = ds.getPointIndex(dataPoint);
					if(pn != -1){
						for(var pi:int = pn - numMouseOverAdjacents; pi < pn + numMouseOverAdjacents; pi++){
							if(pi < 0 || pi >= ds.length) continue;
							var adjPt:Object = ds[pi];
							if(adjPt){
								var aColor:uint = AirQualityColors.getColorForValue(dataSets[0].pollutant,adjPt.value);
								var aPosition:Point = map.locationPoint(new Location(adjPt.lat,adjPt.lon),map.stage)
								_plotTip.graphics.lineStyle(2,0xffffff,0.7);
								_plotTip.graphics.beginFill(aColor,1);
								_plotTip.graphics.drawCircle(aPosition.x - ptPosition.x, aPosition.y - ptPosition.y,(2/3)*pointDiameter -
									 (pointDiameter/3 * Math.abs(pi - pn)/numMouseOverAdjacents));
				    			_plotTip.graphics.endFill();								
							}
						}
					}
				}*/
				PointRenderer.drawPointToGraphics(_plotTip.graphics,dataPoint,null,
					dataSets[0].pollutant,selections.isSelected(dataPoint),true,false,pointDiameter);
				
				//Plot an accentuated version of the point as part of the tooltip
				/*_plotTip.graphics.lineStyle(2,0xffffff,0.7);
				_plotTip.graphics.beginFill(color,1);
				_plotTip.graphics.drawCircle(0,0,(2/3)*pointDiameter);
    			_plotTip.graphics.endFill();
    			_plotTip.graphics.beginFill(0xffffff,1);
    			_plotTip.graphics.drawCircle(0,0,pointDiameter/3);
    			_plotTip.graphics.endFill();*/
			}
			else _plotTip.text = "No Data"
			
			//bitmap.alpha = 0.7;
		}	
			
		public function discardActiveDataTip():void{
			if(_plotTip){
				ToolTipManager.destroyToolTip(_plotTip);
				_plotTip = null;
				dispatchEvent(new DataPointEvent(DataPointEvent.UNHOVER));
			}
			//bitmap.alpha = 1;
		}
		
		
		protected function handleMouseMove(me:MouseEvent):void{
			//locate any points under the mouse
			var pointRadiusDegrees:Number = Math.abs(map.pointLocation(new Point(0,0)).lat 
				- map.pointLocation(new Point(0,pointDiameter/2)).lat); 
			var loc:Location = map.pointLocation(new Point(me.localX,me.localY));
			var mPoints:Array = _quadTree.queryRectangle(new Rectangle(loc.lon - pointRadiusDegrees / 2 + 180,
				loc.lat - pointRadiusDegrees / 2 + 90, pointRadiusDegrees, pointRadiusDegrees));
			
			//If we have points, draw the first
			if(mPoints.length > 0){ 
				drawDataTip(mPoints[0].data);
				dispatchEvent(new DataPointEvent(DataPointEvent.HOVER,mPoints[0].data,new Point(me.stageX,me.stageY)));
			}
			//If no points, throw away any tip we might have
			else discardActiveDataTip();
		}
		
		
		protected function handleMouseOut(me:MouseEvent):void{
			discardActiveDataTip();
		}
		
		
		protected function handleMouseClick(me:MouseEvent):void{
			var pointRadiusDegrees:Number = Math.abs(map.pointLocation(new Point(0,0)).lat 
				- map.pointLocation(new Point(0,pointDiameter/2)).lat); 
			var loc:Location = map.pointLocation(new Point(me.localX,me.localY));
			var mPoints:Array = _quadTree.queryRectangle(new Rectangle(loc.lon - pointRadiusDegrees / 2 + 180,
				loc.lat - pointRadiusDegrees / 2 + 90, pointRadiusDegrees, pointRadiusDegrees));
			
			//If we have points, dispatch an event for the first
			if(mPoints.length > 0){ 
				dispatchEvent(new DataPointEvent(DataPointEvent.CLICK,mPoints[0].data,new Point(me.stageX,me.stageY)));
			}
		}
		
	}
}