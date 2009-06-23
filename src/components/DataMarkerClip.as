package components
{
	import __AS3__.vec.Vector;
	
	import com.modestmaps.Map;
	import com.modestmaps.core.Coordinate;
	import com.modestmaps.events.MapEvent;
	import com.modestmaps.geo.Location;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class DataMarkerClip extends Sprite
	{
		protected var _data:Object;//Vector.<Object>;
		protected var _map:Map;
		
		// setting this.dirty = true will redraw an MapEvent.RENDERED
		protected var _dirty:Boolean;
    	protected var drawCoord:Coordinate; 
		protected var bitmap:Bitmap = new Bitmap();
		protected var plotBitmapData:BitmapData;
		
		protected function get map():Map{ return _map;}
		
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
			plotData(); 
		}
		public function get data():Object{
			return _data;
		}
		
		
		public function DataMarkerClip(map:Map,data:Vector.<Object> = null)
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
		}
		
		
		protected var _plotCount:uint = 0;
		protected var _cachedBitmapData:Object = {};
		
		
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
			
			//If we've already drawn this zoom level, just reuse it
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
				
					//determine location
					var dLoc:Location = new Location(point.lat,point.lon);
					var dPt:Point = _map.locationPoint(dLoc);
		
					//skip if position, level not different from last
					if(prevPoint && prevPoint.level == point.level 
							&& Math.abs(prevPt.x - dPt.x) < pointOverlapTolerance 
							&& Math.abs(prevPt.y - dPt.y) < pointOverlapTolerance){
						continue;
					}  
									
					//draw the point
					if(!prevPoint || prevPoint.level != point.level){
						var color:uint = AirQualityColors.getColorForLevel(point.level);
						plotShape.graphics.clear();
						plotShape.graphics.lineStyle(0.5,0xffffff,0.6);
						plotShape.graphics.beginFill(color,0.6);
						plotShape.graphics.drawCircle(0,0,pointDiameter/2);
	        			plotShape.graphics.endFill();
	    			}
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
		
		/*protected function drawCenterPoint():void{
			var cShape:Shape = new Shape();
			cShape.graphics.lineStyle(1,0xFFFF0000,1);
			cShape.graphics.moveTo(-10,-10);
			cShape.graphics.lineTo(10,10);
			cShape.graphics.moveTo(10,-10);
			cShape.graphics.lineTo(-10,10);
			var cm:Matrix = new Matrix();
			cm.tx = -10;
			cm.ty = -10;
			plotBitmapData.draw(cShape,cm);
		}*/
		
		
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
	}
}