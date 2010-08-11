package data
{
	import commentspace.data.CommentSpaceDataEvent;
	import commentspace.data.EntityTypes;
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
		
		protected var _wm:WorkspaceManager = WorkspaceManager.instance;
		
		public function SelectionSet(){
			loadSelections();
		}
		
		protected function loadSelections():void{
			var onLoaded:Function = function():void{
				//hash results 
				var results:Array = [];
				//FIXME: CommentSpace no longer supports this entity matching method for workspaces. 
				//  We will either need to change to work with the new version of CommentSpace, or 
				//  think about removing selections (which we aren't using anyway) entirely.
				/*for each(var o:Object in _wm.match({type:EntityTypes.SELECTION},"entity")){
					if(o['query']){
						_selections[o['query']] = o;
						results.push(o)
					}	
				}*/
				//dispatch change event
				dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,false,false,
					CollectionEventKind.ADD, -1,-1,results));	
			}
			
			if(_wm.isWorkspaceLoaded) onLoaded();
			else{
				_wm.addEventListener(CommentSpaceDataEvent.WORKSPACE_LOADED,function(ce:CommentSpaceDataEvent):void{
					_wm.removeEventListener(CommentSpaceDataEvent.WORKSPACE_LOADED, arguments.callee);
					onLoaded();
				});
			}
		}
		
		
		public function addSelection(query:*):Object{//property:String, value:*, comparator:String='='):void{
			if(!_selections[query]){
				var s:Object = {type:EntityTypes.SELECTION,query:query};
				_selections[query] = s
				_wm.newEntity(s);		
				return s;
			}
			else return _selections[query]; 
		}
		
		
		public function removeSelection(value:*):void{
			if(_selections[value]){
				var v:* = _selections[value];
				_selections[value] = null;
				_wm.addEventListener(CommentSpaceDataEvent.COMPLETE,function(ce:CommentSpaceDataEvent):void{
					_wm.removeEventListener(CommentSpaceDataEvent.COMPLETE, arguments.callee);
					
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