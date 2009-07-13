package data
{
	import commentspace.data.CommentSpaceDataEvent;
	import commentspace.data.SimpleDBManager;
	
	import flash.events.EventDispatcher;
	
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	
	/**
	 * Identifies a selection in  
	 * @author willettw
	 * 
	 */	
	public class SelectionSet extends EventDispatcher
	{
		protected var _selections:Object = {};		
		
		public var indexByField:String = "id";
		
		
		public function SelectionSet(){
			//loadSelections();
		}
		
		public function addSelection(value:*):void{//property:String, value:*, comparator:String='='):void{
			if(!_selections[value]){
				_selections[value] = value;		
				trace("selections: Add " + value);
				dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
					CollectionEventKind.ADD, -1,-1,[value]));
			}
		}
		
		public function removeSelection(value:*):void{
			if(_selections[value]){
				var v:* = _selections[value];
				_selections[value] = null;
				trace("selections: Removed " + value);
				dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
					CollectionEventKind.REMOVE, -1,-1,[v]));
			}
		}
		
		public function isSelected(dataPoint:Object):Boolean{
			if(!indexByField || !dataPoint[indexByField]) return false;
			return _selections[dataPoint[indexByField]];
		}
		
		
		protected function loadSelections():void{
			var s:SimpleDBManager = new SimpleDBManager();
			//TODO: support for different workspaces
			s.loadData("http://exp.sense.us:8080/commentspace/getfiltered?workspace=Test&type=selection");
			s.addEventListener(CommentSpaceDataEvent.COMPLETE,function(ce:CommentSpaceDataEvent):void{
					var results:Array = [];
					//hash results 
					for each(var o:Object in ce.data){
						if(o['query']){
							_selections[o['query']] = o['query'];
							results.push(o['query'])
						}	
					}
					//dispatch change event
					dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
						CollectionEventKind.ADD, -1,-1,results));	
				});
			
			
			
		}
		
	}
}
/*
class Selection{
	public function Selection(property:String, value:*, comparator:String='=')
	{
		this.property = property;
		this.comparator = comparator;
		this.value = value;
	}
	
	public var property:String;
	public var comparator:String;
	public var value:*;
	
}*/