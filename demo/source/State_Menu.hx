/**
	Menu State
	===================
	
	- This is the main menu state
	- FLXMenu practical example
	
*******************************************/
 
package ;
import djA.DataT;
import djFlixel.D;
import djFlixel.gfx.BoxScroller;
import djFlixel.gfx.pal.Pal_DB32 as DB32; // Cool Haxe Feature
import djFlixel.gfx.statetransit.Stripes;
import djFlixel.other.DelayCall;
import djFlixel.other.FlxSequencer;
import djFlixel.ui.FlxMenu;
import djFlixel.ui.menu.MPageData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.text.FlxText;


class State_Menu extends FlxState
{
	// Scroller ID, used to select asset for the background
	var scid = 0;
	
	// Animated background
	var sc:BoxScroller;

	/** The main menu object */
	var menu:FlxMenu;

	// <gfx.Pal.PAL_DB32> color indexes 
	// The animated background image is going to be colorized with these palette indexes
	var BGCOLS = [
		[1,2],
		[24,25],
		[14,16],
		[3,12],
		[14,25],
		[2,26]
	];
	
	override public function create() 
	{
		super.create();
		
		// -- animated background
		sc = new BoxScroller('im/bg01.png', 0, 0, FlxG.width, FlxG.height);
		sc.autoScrollX = 0.2;
		sc.autoScrollY = 0.2;
		scroller_next();	// This changes the asset and also colorizes it
		add(sc);
		
		// -- the menu
		var m = create_get_menu();
		add(m);
		m.goto('main');	// Will goto that page and open the menu
		
		// -- infos
		var bg1 = new FlxSprite();
			bg1.makeGraphic(FlxG.width, 18, 0xFF000000);
			add(D.align.screen(bg1, '' , 'b')); // '' to leave it alone in the X axis
			
		// text.fix(style), makes all following text.get(..) calls to apply a specific style
		// useful if you want to create a style on the fly and use it multiple times
		// Check the typedef for the style object in <Dtext.h>
 		D.text.fix({c:DB32.COL[21], bc:DB32.COL[1], bt:2});
		var t1 = D.text.get('DJFLIXEL ${D.DJFLX_VER} by John32B.');
			add(D.align.screen(t1, 'l', 'b', 2)); // Add and Align to screen in one call
			
		// Note that I can overlay a style here. This will use the fixed style and
		// also apply a new color
		var t2 = D.text.get('Music "DvD - Deep Horizons"', {c:DB32.COL[22]});
			add(D.align.screen(t2, 'r', 'b', 2 ));
		
		// Unfix the text style. text.get() will now return unstyled text
		D.text.fix();
		
		var t3 = D.text.get('Mouse | [ARROW,WASD] move | [K,V] select | [J,C] cancel', {c:0xFF000000, bc:0xFF727268, bt:2});
		add(D.align.up(t3, bg1));
		
		// --
		D.snd.playV('fx2');
	}//---------------------------------------------------;
	
	
	// -- Change the background scroll graphic/color
	function scroller_next()
	{
		var C = DataT.arrayRandom(BGCOLS).copy();
		C[0] = DB32.COL[C[0]];	// Convert index to real color
		C[1] = DB32.COL[C[1]];
		
		//--
		scid++; if (scid > 5) scid = 1;
		var b = FlxAssets.resolveBitmapData('im/bg0${scid}.png');
			b = D.bmu.replaceColors(b.clone(), [0xFFFFFFFF, 0xFF000000], C);
		sc.loadNewGraphic(b);
	}//---------------------------------------------------;
	
	
	function create_get_menu()
	{
		// -- Create
		var m = new FlxMenu(32, 32, 140);
		
		// -- Create some pages
		// Note: Haxe supports multiline strings, this is OK:
		m.createPage('main','This is an FlxMenu').add('
			-|Slides Demo 		|link|sdemo
			-|Menu Demo			|link|@mdemo
			-|FlxAutotext Demo	|link|autot
			-|Simple Game Demo	|link|game1
			-|Options			|link|@options
			-|Reset				|link|rst|?pop=:YES:NO');
			 
		m.createPage('options', 'Options').add('
			-|Fullscreen	|toggle|fs
			-|Smoothing		|toggle|sm
			-|Volume		|range|vol| 0,100 | step=5'+
			#if(desktop) // preprocessors don't work inside a string
			'-|Windowed Mode	|range|winmode|1,${D.MAX_WINDOW_ZOOM}' + 
			#end
			'-|Change Background	|link|bgcol
			 -|Back			| link | @back');
			 
			 
		// -- Styling
		// STP is the object that holds STYLE data for the Menu Pages
		// Every FlxMenu comes with a predefined default
		// Here I am overriding some fields.
		// I could also use overlayStyle();
		m.STP.item.text = {
			f:"fnt/blocktopia.ttf",
			s:16,
			bt:1, 		// Border Type 1:Shadow
			so:[1, 1]	// Shadow Offset (1,1) pixels
		};
		
		// Text Color
		m.STP.item.col_t = {
			idle:DB32.COL[21],
			focus:DB32.COL[28],
			accent:DB32.COL[29],
			dis:DB32.COL[25],		// Disabled
			dis_f:DB32.COL[23], 	// Disabled focused
		};
		
		// Border Color
		m.STP.item.col_b = {
			idle:DB32.COL[1],
			focus:DB32.COL[0]
		};
		
		
		//m.stHeader = {
			//f:"fnt/blocktopia.ttf",
			//s:16,bt:2,bs:1,
			//c:DB32.COL[8],
			//bc:DB32.COL[27]
		//};
		//m.PARAMS.header_CPS = 30;
		//m.PARAMS.page_anim_parallel = true;
			

		

		//var p = m.createPage('mdemo').add('
			//'Mousewheel to scroll|link|0', // Putting 0 as id, because it needs an ID
			//'or buttons to navigate as normal|link|0',
			//':test label:|label',
			//'Disabled - |link|dtest',
			//'Toggle above ^|link|dtog',
			//'----|link|0',
			//'Toggle Item|toggle|c=false|id=0', // Note. I need to specify "id=0", unlike links which don't need "id="
			//'List Item|list|list=one,two,three,four,five|c=0|id=0',
			//'Range Item|range|range=0,1|step=0.1|c=0.5|id=0',
			//'BACK|link|@back'
		//]);
		
		//---------------------------------------------------;
		// Example :
		// Customize the ItemStyle and ListStyle for this specific page
		
		//p.params.stI = {
			//text : {f:"fnt/wc.ttf", s:16, bt:2},
			//box_bm : [ // Custom checkbox icons
				//D.ui.getIcon(12, 'ch_off'), D.ui.getIcon(12, 'ch_on')
			//], 
			//ar_bm : [ // Custom Slider/List Arrows
				//D.ui.getIcon(12, 'ar_left'), D.ui.getIcon(12, 'ar_right')
			//],
			//ar_anim : "2,2,0.5"
		//};
		//p.params.stL = {
			//align:'justify',
			//other:'yes'
		//}
		//---------------------------------------------------;

		// More initialization of some items 
		//m.pages.get('mdemo').get('dtest').disabled = true;
		//m.pages.get('main').get('rst').data.tStyle = {bt:2, s:8, f:null}; // < Change the popup text style
		
		
		/** Handle Page Events, keep track when I am going in and out of pages 
		 * (MenuEvent->PageID) */
		m.onMenuEvent = (ev, id)->{
			
			if (ev == pageCall) {
				D.snd.playV('cursor_high', 0.6);
			}else
			if (ev == back){
				D.snd.playV('cursor_low');
			}
			
			// Just went to the options page
			// I want to alter the Item Datas to reflect the current settings
			if (ev == page && id == "options") {
				// (2) , is the index starting from 0, I could pass the ID to get the item also
				m.item_update(0, (t)->t.set(FlxG.fullscreen) );
				m.item_update(1, (t)->t.set(D.SMOOTHING) );
				m.item_update(2, (t)->t.set(Std.int(FlxG.sound.volume * 100)) );	
			}
		};
		
		/** Handle Item events. When you interact with items they will fire here
		 * (ItemEvent->Item) */
		m.onItemEvent = (ev, item)->{
			
			// -
			if (ev == fire) switch(item.ID){
				case "fs":
					FlxG.fullscreen = item.get();
				case "sm":
					D.SMOOTHING = item.get();
				case "vol":
					FlxG.sound.volume = cast(item.get(),Float) / 100;
				case "rst":
					Main.goto_state(State_Logos);
				case "bgcol":
					scroller_next();
				case "dtog":
					// Get the disabled item and modify it with this function
					m.item_update('mdemo', 'dtest', (it)->{
						it.disabled = !it.disabled;
						it.label = it.disabled?'Disabled :-(':'Enabled - :-)';
					});
				case "winmode":
					D.setWindowed(item.get());
					m.item_update(0, (t)->{t.P.c = FlxG.fullscreen; });
				case "sdemo": Main.goto_state(State_Slides);
				case "autot": Main.goto_state(State_Autotext);
				case "game1": Main.goto_state(game1.State_Game1);
				case _:
			};
			
			// -- Sounds
			switch(ev) {
				case fire:
					D.snd.playV('cursor_high',0.7);
				case focus:
					D.snd.playV('cursor_tick',0.4);
				case invalid:
					D.snd.playV('cursor_error');
				case _:
			};
		}//
		
		return m;
	}//---------------------------------------------------;
	
	
}// --