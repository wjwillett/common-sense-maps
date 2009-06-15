package components
{
	import com.modestmaps.geo.Location;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;

	public class FlagMarker extends Sprite
	{
		/********** Local Vars ************************************************/
		
		public var location:Location;
		public var zoom:int;
		public var id:uint;
		
		[Embed(source="../assets/flag_blue.png")]
		protected const BlueFlagIcon:Class;

		//[Embed(source="../assets/comment.png")]
		[Embed(source="../assets/comment_flag.png")]
		protected const CommentIcon:Class;
		
		protected static var flagGlowFilter:GlowFilter = new GlowFilter(0x4455ff,1,10,10,2);
		
		protected var _flag:DisplayObject;
		
		
		/********** Methods ************************************************/
				
		public function FlagMarker(location:Location,zoom:int,id:uint=0)
		{
			//if no id provided, generate a new pseudo-random integer id
			this.id = (id !=0 ? id : int(Math.random()*uint.MAX_VALUE));

			this.location = location;
			this.zoom = zoom;

			this.useHandCursor = true;
			this.buttonMode = true;
			this.mouseChildren = false;
			
			//hover listeners
			addEventListener(MouseEvent.MOUSE_OVER,function(e:Event):void{if(_flag)_flag.alpha = 0.8});
			addEventListener(MouseEvent.MOUSE_OUT,function(e:Event):void{if(_flag)_flag.alpha = 1});
			
			draw();
		}
		
		
		protected function draw():void{
			while(this.numChildren > 0) removeChildAt(0);
			_flag = new CommentIcon();
			_flag.y = -_flag.height;
			_flag.x = -11;
			
			this.addChild(_flag);
		}
		
		public function highlight(show:Boolean=true):void{
			filters = show ? [flagGlowFilter] : null;
		}
	}
}