package components
{
	import flash.display.Sprite
	import com.modestmaps.Map
	import flash.display.Bitmap
	import flash.events.MouseEvent
	import com.modestmaps.core.MapExtent
	import flash.geom.Rectangle
	import mx.controls.Image
	import com.modestmaps.events.MapEvent
	import com.modestmaps.TweenMap  
	import mx.core.UIComponent
	 
	public class IconControls extends Sprite
	{
	  // icons "free to use in any kind of project unlimited times" from http://www.icojoy.com/articles/26/
	  [Embed(source="assets/map_right.png")]
	  protected var RightImage:Class
	 
	  [Embed(source="assets/map_down.png")]
	  protected var DownImage:Class
	 
	  [Embed(source="assets/map_left.png")]
	  protected var LeftImage:Class
	 
	  [Embed(source="assets/map_up.png")]
	  protected var UpImage:Class
	 
	  [Embed(source="assets/map_out.png")]
	  protected var OutImage:Class
	 
	  [Embed(source="assets/map_in.png")]
	  protected var InImage:Class
	 
//	  [Embed(source="images/001_20.png")]
//	  protected var HomeImage:Class
	 
	  protected var map:TweenMap
	 
	  public function IconControls(map:TweenMap):void
	  {
	  	this.map = map
	 
	    this.mouseEnabled = false
	    this.mouseChildren = true
	 
	    var right:Sprite = new Sprite()
	    var down:Sprite = new Sprite()
	    var left:Sprite = new Sprite()
	    var up:Sprite = new Sprite()
	    var zout:Sprite = new Sprite()
	    var zin:Sprite = new Sprite()
	    var home:Sprite = new Sprite()
	 
	    var buttons:Array = [ right, down, left, up, zout, zin]
	    var imageClasses:Array = [ RightImage, DownImage, LeftImage, UpImage, OutImage, InImage]
	    var actions:Array = [ map.panRight, map.panDown, map.panLeft, map.panUp, map.zoomOut, map.zoomIn]
	    for each (var sprite:Sprite in buttons) {
	      var ImageClass:Class = imageClasses.shift() as Class
	      sprite.addChild(new ImageClass() as Bitmap)
	      sprite.useHandCursor = sprite.buttonMode = true
	      sprite.addEventListener(MouseEvent.CLICK, actions.shift(), false, 0, true)
	      addChild(sprite)
	    }
	 
	    left.x = 5
	    up.x = down.x = left.x + left.width + 5
	    right.x = down.x + down.width + 5
	 
	    up.y = 5
	    left.y = down.y = right.y = up.y + up.height + 5
	 
	    zout.x = zin.x = right.x + right.width + 10
	    zin.y = up.y
	    zout.y = zin.y + zin.height + 5
	 
	    home.x = zout.x + zout.width + 10
	    home.y = zout.y
	 
	    var rect:Rectangle = getRect(this)
	    rect.inflate(rect.x, rect.y)
	 
	    graphics.beginFill(0xff0000, 0)
	    graphics.drawRect(rect.x, rect.y, rect.width, rect.height)
	    graphics.endFill()    
	 
//	    map.addEventListener(MapEvent.RESIZED, onMapResize)
//	    onMapResize(null)
	  }
	 
//	  protected function onMapResize(event:MapEvent):void
//	  {
//	    this.x = 10
//	    this.y = map.getHeight() - this.height - 10    
//	  }
	 
//	  protected function onHomeClick(event:MouseEvent):void
//	  {
//	    map.tweenExtent(new MapExtent(85, -85, 180, -180))
//	  }
	}
}