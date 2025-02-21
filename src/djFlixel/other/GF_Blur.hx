/**
   Global Filter - Blur
   - create right after FlxGame is created
   - auto adds and handles events
   
   - 
**/

package djFlixel.other;
import flixel.FlxG;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;

class GF_Blur 
{
	public var enabled(default, set):Bool = false;
	
	var MAX:Float;	// In desktop targets, when resizing, limit blur to this
	var filters:Array<BitmapFilter>;
	var bf:BlurFilter;
	
	/**
	   @param	val Initial Value. Useful for HTML5, because once set, it won't change
	   @param	q Quality. How many passes to apply {1,2,3} is the highest
	**/
	public function new(val:Float = 1, max:Float = 1.65, q:Int = 1)
	{
		// Going to be set properly at "onResize()" which is automatically called
		bf = new BlurFilter(val, val, q);
		
		MAX = max;
		
		filters = [ bf ];
		
		#if (desktop)
		FlxG.signals.gameResized.add(onResize);
		#end
		
		#if (flash)
		FlxG.signals.postStateSwitch.add(()->{
			enabled = enabled; // trigger an activation
		});
		#end
		
		@:privateAccess D._cycle_filters = () ->{
			enabled = !enabled;
		}
	}//---------------------------------------------------;
	
	public function set_enabled(val:Bool):Bool
	{
		enabled = val;
		
		#if (flash)
			for (c in FlxG.cameras.list) c.antialiasing = enabled;
			return enabled;
			// Filter blur is very slow in flash
			// Quick hacky way to enable some smoothing
		#end
		
		if (enabled) {
			FlxG.game.setFilters(filters);
		}else{
			FlxG.game.setFilters([]);
		}
		return enabled;
	}//---------------------------------------------------;
	
	
	#if (desktop)
	function onResize(x, y)
	{
		// Recalculate the blur filter to match the new window size?
		var rx = (x / FlxG.width);
		var ry = (y / FlxG.height);
		
		if (rx <= 1) bf.blurX = 0; else {
			bf.blurX = rx * 0.5;
			if (bf.blurX > MAX) bf.blurX = MAX;
		}
		
		if (ry <= 1) bf.blurY = 0; else {
			bf.blurY = ry * 0.5;
			if (bf.blurY > MAX) bf.blurY = MAX;
		}
		
		trace('GF_BLUR::resize() , blurX = ${bf.blurX} | blurY=${bf.blurY}');
		
	}//---------------------------------------------------;
	#end
}