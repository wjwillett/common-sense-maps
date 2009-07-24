package data
{
	import commentspace.data.CommentSpaceDataEvent;
	import commentspace.data.WorkspaceManager;
	
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
		
		protected var _dbManager:WorkspaceManager; //= WorkspaceManager.getWorkspaceManager("Test");
		
		public function SelectionSet(){
			//loadSelections();
		}

		protected function loadSelections():void{
			var onLoaded:Function = function():void{
				//hash results 
				var results:Array = [];
				for each(var o:Object in _dbManager.match({type:"selection"},"entity")){
					if(o['query']){
						_selections[o['query']] = o;
						results.push(o)
					}	
				}
				//dispatch change event
				dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
					CollectionEventKind.ADD, -1,-1,results));	
			}
			
			if(_dbManager.isWorkspaceLoaded) onLoaded();
			else{
				_dbManager.addEventListener(CommentSpaceDataEvent.WORKSPACE_LOADED,function(ce:CommentSpaceDataEvent):void{
					_dbManager.removeEventListener(CommentSpaceDataEvent.WORKSPACE_LOADED, arguments.callee);
					onLoaded();
				});
			}
		}

		
		public function addSelection(query:*):void{//property:String, value:*, comparator:String='='):void{
			if(!_selections[query]){
				var s:Object = {type:'selection',query:query};
				_selections[query] = s
				_dbManager.addEntity(s);
				_dbManager.save(s);		
				//_dbManager.sendRequest("http://exp.sense.us:8080/commentspace/postselection?query=" + s);
				/*_dbManager.addEventListener(CommentSpaceDataEvent.COMPLETE,function(ce:CommentSpaceDataEvent):void{
						_dbManager.removeEventListener(CommentSpaceDataEvent.COMPLETE, arguments.callee);
						
						dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
							CollectionEventKind.ADD, -1,-1,[q]));
					});*/
			}
		}

		
		public function removeSelection(value:*):void{
			if(_selections[value]){
				var v:* = _selections[value];
				_selections[value] = null;
				//_dbManager.sendRequest("http://exp.sense.us:8080/commentspace/postselection?id=" + value.toString());
				_dbManager.addEventListener(CommentSpaceDataEvent.COMPLETE,function(ce:CommentSpaceDataEvent):void{
						_dbManager.removeEventListener(CommentSpaceDataEvent.COMPLETE, arguments.callee);
	
						dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
							CollectionEventKind.REMOVE, -1,-1,[v]));						
					});
			}
		}


		//FIXME: These methods work only for super-simple selection-by-id
		
		public function isSelected(dataPoint:Object):Boolean{
			if(!indexByField || !dataPoint[indexByField]) return false;
			return _selections[dataPoint[indexByField]];
		}
		
		public function getSelections(dataPoint:Object):Array{
			if(!indexByField || !dataPoint[indexByField]) return [];
			var matches:Array = [];
			for each(var s:Object in _selections){
				if(s.query == dataPoint.id) matches.push(s);	
			}
			return matches;
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