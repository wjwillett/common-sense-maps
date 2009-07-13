package etc
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	public class PointRenderer
	{
		
		protected var plotShape:Shape = new Shape();
		protected var translationMatrix:Matrix = new Matrix();
		
		protected var bitmapData:BitmapData;
		protected var pointDiameter:Number;
		protected var pointOverlapTolerance:Number;
		
		//Embedded Comment Icon
		[Embed(source="../assets/comment_flag_mini.png")]
		protected static const CommentIcon:Class;
		protected static const ciBitmap:Bitmap = new CommentIcon() as Bitmap;
		
		protected var prevPoint:Object;
		protected var prevPos:Point;
		
		public function PointRenderer(bitmapData:BitmapData,pointDiameter:Number,pointOverlapTolerance:Number){
			
			this.bitmapData = bitmapData;
			this.pointDiameter = pointDiameter;
			this.pointOverlapTolerance = pointOverlapTolerance;
		}

		public function ignorePrevPoints():void{
			prevPoint = null;
			prevPos = null;
		}
		
		public function plotPoint(point:Object, position:Point, pollutant:String, isSelected:Boolean=false, isHovered:Boolean=false):void{
			
			if(!point.cat)point.cat = AirQualityColors.getAQICategoryForValue(pollutant,point.value);
					

			//skip if position, category not different from last
			if(!isSelected && prevPoint //&& prevPoint.cat == point.cat 
					&& Math.abs(prevPos.x - position.x) < pointOverlapTolerance 
					&& Math.abs(prevPos.y - position.y) < pointOverlapTolerance){
				return;
			}  
			
			drawPointToGraphics(plotShape.graphics,point,position,pollutant,isSelected,isHovered,pointDiameter);
			
			translationMatrix.tx = position.x;
			translationMatrix.ty = position.y;
			
			bitmapData.draw(plotShape,translationMatrix);
			
			prevPoint = point;
			prevPos = position;
		}

		public static function drawPointToGraphics(graphics:Graphics, point:Object, position:Point, 
				pollutant:String, isSelected:Boolean=false, isHovered:Boolean=false,diameter:Number=5):void{
			//determine location
			var hasGPS:Boolean = !(!point.lat || point.lat == "None");
							
			//draw the point
			var color:uint = AirQualityColors.getColorForValue(pollutant,point.value);
			graphics.clear();
			//Highlight selected points
			if(isSelected){
				graphics.beginFill(0x6ba7fe,isHovered ? 0.8 : 0.6);
				graphics.drawCircle(0,0,isHovered ? diameter * 1.3 : diameter);
				graphics.endFill();
				//draw comment icon
				graphics.beginBitmapFill(ciBitmap.bitmapData,new Matrix(1,0,0,1,diameter/4,-diameter/3 - 14));
				graphics.drawRect(diameter/4,-diameter/3 - 14,14,14);
				graphics.endFill();
			}
			graphics.lineStyle(0.5,hasGPS ? 0xffffff : 0x777777, isHovered ? 1 : 0.6);
			graphics.beginFill(color,isSelected ? 1 : 0.6);
			graphics.drawCircle(0,0,diameter/2);
			graphics.endFill();
			//grey out the outlines and centers of points with no lat/lon
			if(!hasGPS){
				graphics.lineStyle(0,0,0);
				graphics.beginFill(0x777777,0.8);
				graphics.drawCircle(0,0,diameter/5);
				graphics.endFill();
			}
			//draw center circle on hovered points
			if(isHovered){
				graphics.lineStyle(0,0,0);
				graphics.beginFill(0xffffff,1);
				graphics.drawCircle(0,0,diameter/4);
				graphics.endFill()
			}
		}  



	}
}