package components
{
	import __AS3__.vec.Vector;
	
	import com.modestmaps.Map;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.geo.Location;
	
	import etc.AirQualityColors;
	
	import events.DataPointEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.controls.ToolTip;
	import mx.managers.ToolTipManager;
	
	import papervision3Dqtree.QuadTree;
	import papervision3Dqtree.QuadTreeItem;
	

	public class AirQualityMapLayer extends Sprite
	{
		protected var _data:Object;//Vector.<Object>;
		protected var _map:Map;
		
		// setting this.dirty = true will redraw an MapEvent.RENDERED
		protected var _dirty:Boolean;
    	protected var drawCoord:Coordinate; 
		protected var bitmap:Bitmap = new Bitmap();
		protected var plotBitmapData:BitmapData;
		protected var _plotCount:uint = 0;
		protected var _cachedBitmapData:Object = {};
		protected var _quadTree:QuadTree = new QuadTree(360,180,8);
		
		protected function get map():Map{ return _map;}
		
		public var pollutant:String = AirQualityColors.PM_25_24HR;
		public var pointOverlapTolerance:Number = 11;
		public var zoomTolerance:Number = 5; 
		public var pointDiameter:Number = 12;
		
		
		/**
		 * A data object should be an Object containing
		 *  sets of points (as Vector.<Object>s) 
		 *  indexed by the URI of that set of points.  
		 * @param d
		 * 
		 */		
		public function set data(d:Object):void{
			_data = d;
			for each(var ds:Vector.<Object> in d){
				addToQuadTree(ds);
			}
			plotData(); 
		}
		public function get data():Object{
			return _data;
		}
		
		public function AirQualityMapLayer(map:Map,data:Vector.<Object> = null)
		{
			super();
			
			this.mouseEnabled = false;
			
			this._map = map;
			this.addChild(bitmap);
			this.data = data;
			
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
		}
		
		public function refresh(force:Boolean=false):void{
			if(force){
				 _cachedBitmapData = {};
				 _quadTree.clearItems();
				 for each(var ds:Vector.<Object> in _data) addToQuadTree(ds);
				 _dirty = true;
			}
			plotData();
		}
		
		
		protected function addToQuadTree(dataSet:Vector.<Object>):void{
			for each(var dp:Object in dataSet){
				if(!(dp.lat || dp.lon)) continue;
				var dpr:Rectangle = new Rectangle(Number(dp.lon) + 180,Number(dp.lat) + 90,0,0)
				var dpq:QuadTreeItem = new QuadTreeItem(dp,dpr);
				_quadTree.insertItem(dpq);
			}
		}

		
		protected function plotData(e:Event=null):void{
			if (!dirty) {
	    		return;
	    	}
	    	
	    	trace(_plotCount++ + ". " + (e ? e.type : "") + " -> plotData()");
	    	
	    	drawCoord = map.grid.centerCoordinate.copy();
			
			//Centers this clip over the map
	    	this.x = map.getWidth() / 2;
	    	this.y = map.getHeight() / 2;	    	
	        scaleX = scaleY = 1.0;
			
			//If no data do nothing
			if(!data || data.length == 0) return;
			
			//Set up the bitmapData we'll paint into
			//TODO: This will break for displays bigger than 2800px.
			var w:Number = Math.min(2880, 2*map.getWidth());
        	var h:Number = Math.min(2880, 2*map.getHeight());
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
			
			//If we've already drawn this zoom , just reuse it
			//FIXME: This will probably no longer work once we start using multiple datasets, etc.
			if(_cachedBitmapData[drawCoord.zoom]){
				var cachedBMD:BitmapData = _cachedBitmapData[drawCoord.zoom].bitmap;
				var cachedCenter:Location = _cachedBitmapData[drawCoord.zoom].center;
				var centerPoint:Point = map.locationPoint(map.getCenter());
				var cachedCenterPoint:Point = map.locationPoint(cachedCenter);
				var tx:Number = cachedCenterPoint.x - centerPoint.x;
				var ty:Number = cachedCenterPoint.y - centerPoint.y;
				
				//only reuse if we're translating by a small enough distance that the old bitmap will still work
				if(Math.abs(ty) + map.getHeight()/2 < h/2 && Math.abs(tx) + map.getWidth()/2 < w/2){  
					var translateMatrix:Matrix = new Matrix();
					translateMatrix.tx = tx;
					translateMatrix.ty = ty;
					plotBitmapData.draw(cachedBMD,translateMatrix);
					dirty = false;
					return;
				}
			}

			//prep the shape object we'll use to draw the points
			var plotShape:Shape = new Shape();
			var translationMatrix:Matrix = new Matrix();
			
			plotBitmapData.lock();
			
			//for each of the sets of points...
			for each(var pSet:Vector.<Object> in _data){
				var prevPoint:Object;
				var prevPt:Point;
				//iterate through recorded points
				for(var i:int=0; i < pSet.length; i++){
					var point:Object = pSet[i]; 
					if(!point.cat)point.cat = AirQualityColors.getAQICategoryForValue(pollutant,point.value);
				
					//determine location
					var dLoc:Location = new Location(point.lat,point.lon);
					var dPt:Point = _map.locationPoint(dLoc);
		
					//skip if position, AQI category not different from last
					if(prevPoint && prevPoint.cat == point.cat 
							&& Math.abs(prevPt.x - dPt.x) < pointOverlapTolerance 
							&& Math.abs(prevPt.y - dPt.y) < pointOverlapTolerance){
						continue;
					}  
									
					//draw the point
 					var color:uint = AirQualityColors.getColorForAQICategory(point.cat);
					plotShape.graphics.clear();
					plotShape.graphics.lineStyle(0.5,0xffffff,0.6);
					plotShape.graphics.beginFill(color,0.6);
					plotShape.graphics.drawCircle(0,0,pointDiameter/2);
        			plotShape.graphics.endFill();
					translationMatrix.tx = dPt.x + (w - map.getWidth()) / 2;
					translationMatrix.ty = dPt.y + (h - map.getHeight()) / 2;
					
					plotBitmapData.draw(plotShape,translationMatrix);
					
					
					prevPoint = point;
					prevPt = dPt;
				}
			}
			
			plotBitmapData.unlock();
			
			//save bitmapData for later
			var backupBitmapData:BitmapData  = new BitmapData(plotBitmapData.width,plotBitmapData.height,true,0x00000000);
			backupBitmapData.draw(plotBitmapData);
			_cachedBitmapData[drawCoord.zoom] = {bitmap:backupBitmapData,center:map.getCenter()};
			
			dirty = false;
		}
		
		
		protected function onMapExtentChanged(event:MapEvent):void
	    {
	    	_cachedBitmapData = {}; //clear all cached bitmap data
			dirty = true;	    	
	    }
	    
	    protected function onMapPanned(event:MapEvent):void
	    {
	    	if (drawCoord) {
		        var p:Point = map.grid.coordinatePoint(drawCoord);
		        this.x = p.x;
	    	    this.y = p.y;
	    	}
	    	else {
	    		dirty = true;
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
		     		dirty = true;	
		     	}
	        }
	        else { 
		        dirty = true;
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
		    dirty = true;
	    }
	    
	    protected function onMapStopZooming(event:MapEvent):void
	    {
	        dirty = true;
	    }
	    
	    protected function onMapResized(event:MapEvent):void
	    {
	        x = map.getWidth() / 2;
	        y = map.getHeight() / 2;
	        dirty = true;
	        plotData(); // force redraw because flash seems stingy about it
	    }
	    
		    ///// Invalidations...
	    
		protected function set dirty(d:Boolean):void
		{
			_dirty = d;
			if (d) {
				if (stage) stage.invalidate();
			}
		}
		
		protected function get dirty():Boolean
		{
			return _dirty;
		}
		
		/****************************** Tooltipping Methods ************************************/
		protected var _plotTip:ToolTip;
			
		/**
		 * Draws and positions a tooltip for the given datapoint.
		 */
		public function drawDataTip(dataPoint:Object):void{
			
			var overPos:Point = map.locationPoint(new Location(dataPoint.lat,dataPoint.lon),map.stage); 
			if(!_plotTip)_plotTip = ToolTipManager.createToolTip(dataPoint.value,overPos.x,overPos.y) as ToolTip;
		
			//color the tip and add additional text if possible
			if(dataPoint.value){
				var cat:String = AirQualityColors.getAQICategoryForValue(pollutant,dataPoint.value);
				var color:uint = AirQualityColors.getColorForAQICategory(cat);
				_plotTip.setStyle("backgroundColor",color);
				_plotTip.setStyle("backgroundAlpha",0.7);
				var time:Number = Number(dataPoint.time * 1000);
				var date:Date = new Date(time);
				_plotTip.text = date + "\n" + dataPoint.value + " (" + cat + ")";
				_plotTip.x = overPos.x;
				_plotTip.y = overPos.y;
				
				//Plot an accentuated version of the point as part of the tooltip
				_plotTip.graphics.lineStyle(2,0xffffff,0.7);
				_plotTip.graphics.beginFill(color,1);
				_plotTip.graphics.drawCircle(0,0,(2/3)*pointDiameter);
    			_plotTip.graphics.endFill();
    			_plotTip.graphics.beginFill(0xffffff,1);
    			_plotTip.graphics.drawCircle(0,0,pointDiameter/3);
    			_plotTip.graphics.endFill();
			}
			else _plotTip.text = "No Data"
		}	
			
		public function discardActiveDataTip():void{
			if(_plotTip){
				ToolTipManager.destroyToolTip(_plotTip);
				_plotTip = null;
				dispatchEvent(new DataPointEvent(DataPointEvent.UNHOVER));
			}
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
				dispatchEvent(new DataPointEvent(DataPointEvent.HOVER,mPoints[0].data));
			}
			//If no points, throw away any tip we might have
			else discardActiveDataTip();
		}
		
		protected function handleMouseOut(me:MouseEvent):void{
			discardActiveDataTip();
		}
	}
}