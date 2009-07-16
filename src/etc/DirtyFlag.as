package etc
{
	public class DirtyFlag
	{
		public function DirtyFlag(level:int=CLEAN)
		{
			if(level > _level && level <= DIRTY)_level = level;
		}

		public static const DIRTY:int = 2;	//Needs full redraw
		public static const APPEND:int = 1;	//Needs append to existing
		public static const CLEAN:int = 0;	//Is clean
			
		protected var _level:int = 0;

		public function dirty(level:int=DIRTY):int{
			if(level > _level && level <= DIRTY)_level = level;
			return _level;	
		}
		
		public function clean():int{
			_level = CLEAN;
			return _level;
		}
		
		public function get level():int{ return _level;}
		
		public function check(level:int=DIRTY):Boolean{
			return (level == _level);
		}

	}
}