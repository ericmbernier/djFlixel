/***********************************************************************
 * A Panel with a solid background that pops up with an animation
 * 
 * - You can use the width/height as soon as you create it, 
 * 		so you can align this using D.align, etc.
 * 
 * Usage: 
 * -------
 * 	var p = new PanelPop(200, 96, {colorBG:0xFF3344AA,time:0.2});
 *  add(p);
 * 	p.start(()->{ text.show(); unpause(); etc(); });
 * 
 ********************************************************************/

 
package djFlixel.gfx;

import djA.DataT;
import djFlixel.other.StepTimer;
import flash.display.BitmapData;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Rectangle;


class PanelPop extends FlxSprite
{
	static var DEF_PAR = {
		bm:null,			// Custom BitmapData to use. Null for DJFlixel default
		sizes:[8,8,8,8],	// Slice Rectangle sized, x,y,width,height of the center
		colorBG:0xFF8B8B8B,	// Colorize the BG color of the default graphic. 0 for none
		
		// Growing Steps, Ratio of the final width/size. Make sure the have same length
		stepW:[0.15, 1, 1, 1],
		stepH:[0.25, 0.5, 0.7, 1],
		time:0.5,					// Time to take to open the panel
	};
	
	var P:Dynamic;		// Running parameters
	var sb:BitmapData;	// Current source slice9 compatible bitmap.
	var sr:Rectangle;	// Slice Rect.
	var steps:Int;		// stepW.length
	var timer:StepTimer;
	/**
	   @param	WIDTH Final Width
	   @param	HEIGHT Final Height
	   @param	PAR Parameters, check <DEF_PAR> field of this class
	**/
	public function new(WIDTH:Int, HEIGHT:Int, ?PAR:Dynamic)
	{
		super();
		makeGraphic(WIDTH, HEIGHT, 0x00000000);
		P = DataT.copyFields(PAR, Reflect.copy(DEF_PAR));
		sb = P.bm;
		if (sb == null) {
			sb = D.ui.atlas.get_bn('panel');
			if (P.colorBG != 0){
				D.bmu.replaceColor(sb, 0xFFFF0000, P.colorBG);
			}
		}
		var a = P.sizes;
		sr = new Rectangle(a[0], a[1], a[2], a[3]);
		steps = P.stepW.length;
		// ----
		
	}//---------------------------------------------------;
	
	public function start(?onComplete:Void->Void):PanelPop
	{
		if (timer != null) {
			clear();
			timer.destroy();
		}
		timer = new StepTimer((a, b)->{
			renderStep(a);
			if (b){
				timer = FlxDestroyUtil.destroy(timer);
				if (onComplete != null) onComplete();
			}
		});
		timer.start(0, steps - 1, P.time);
		return this;
	}//---------------------------------------------------;
	override public function destroy():Void 
	{
		timer = FlxDestroyUtil.destroy(timer);
		super.destroy();
	}//---------------------------------------------------;
	/** Clear the bitmap */
	public function clear()
	{
		var rr = new Rectangle(0, 0, pixels.width, pixels.height);
		pixels.fillRect(rr, 0x00000000);
		dirty = true;
	}//---------------------------------------------------;
	
	// Render a panel ratio from predefined
	function renderStep(st:Int)
	{
		var dw = Math.floor(Math.max(sr.x * 2, P.stepW[st] * pixels.width));
		var dh = Math.floor(Math.max(sr.y * 2, P.stepH[st] * pixels.height));
		D.bmu.copyOn(
			D.bmu.scale9(sb, sr, dw, dh), 
			pixels,
			Math.floor((pixels.width - dw) / 2),
			Math.floor((pixels.height - dh) / 2)
		);
		dirty = true;
	}//---------------------------------------------------;
	
}// --