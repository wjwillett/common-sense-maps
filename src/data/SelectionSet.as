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
		
		protected var _dbManager:SimpleDBManager = new SimpleDBManager("CommonSenseTest");
		
		public function SelectionSet(){
			//loadSelections();
		}

		protected function loadSelections():void{
			var s:SimpleDBManager = new SimpleDBManager("CommonSenseTest");
			_dbManager.sendRequest("http://exp.sense.us:8080/commentspace/getfiltered?type=selection");
			_dbManager.addEventListener(CommentSpaceDataEvent.COMPLETE,function(ce:CommentSpaceDataEvent):void{
					_dbManager.removeEventListener(CommentSpaceDataEvent.COMPLETE, arguments.callee);
					
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

		
		public function addSelection(value:*):void{//property:String, value:*, comparator:String='='):void{
			if(!_selections[value]){
				_selections[value] = value;		
				_dbManager.sendRequest("http://exp.sense.us:8080/commentspace/postselection?query=" + value.toString());
				_dbManager.addEventListener(CommentSpaceDataEvent.COMPLETE,function(ce:CommentSpaceDataEvent):void{
						_dbManager.removeEventListener(CommentSpaceDataEvent.COMPLETE, arguments.callee);
						
						dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
							CollectionEventKind.ADD, -1,-1,[value]));
					});
			}
		}

		
		public function removeSelection(value:*):void{
			if(_selections[value]){
				var v:* = _selections[value];
				_selections[value] = null;
				_dbManager.sendRequest("http://exp.sense.us:8080/commentspace/postselection?id=" + value.toString());
				_dbManager.addEventListener(CommentSpaceDataEvent.COMPLETE,function(ce:CommentSpaceDataEvent):void{
						_dbManager.removeEventListener(CommentSpaceDataEvent.COMPLETE, arguments.callee);
	
						dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
							CollectionEventKind.REMOVE, -1,-1,[v]));						
					});
			}
		}

		
		public function isSelected(dataPoint:Object):Boolean{
			if(!indexByField || !dataPoint[indexByField]) return false;
			return _selections[dataPoint[indexByField]];
		}
		
		public function getSelections(dataPoint:Object):Array{
			if(!indexByField || !dataPoint[indexByField]) return [];
			return [_selections[dataPoint[indexByField]]];
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