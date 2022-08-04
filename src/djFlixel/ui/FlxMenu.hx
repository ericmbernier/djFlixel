/**
== FlxMenu
  - Multi-page menu system 
  ----------------------------------------------
  
  - It manages multiple <MPages> objects to offer a multi page menu system
  - It handles changing pages when called from other pages 
  - Offers various events with callbacks. e.g. for when an item was fired or hovered
  - <MPage> is a sprite group that takes <MPageData> and creates a single page based on that data
  - To use FLXMenu you must first give it Page Data with the <MPageData> structure
  - Info on how to create <MPageData> to feed to FlxMenu you can find in 
  - Check the examples and the (demo) folder on how to initialize and use this
  

== Very Simple Menu Example
  ------------------------
  
	var menu = new FlxMenu(32,32);
	
	// Haxe supports multi-line strings just fine
	menu.createPage("main").add("
	  -| New Game   | link   | ng 
	  -| Options    | link   |@options
	  -| Quit       | link   | id_q  | ?pop=Really Quit?:Yes:No ");
	 
	menu.createPage("options").add("
		-| Music  | toggle | id_togg
		-| Lives  | range  | id_rang | 1,9
		-| Back   | link   |@back ");
		
	menu.onItemEvent = (event, item) -> {
		if(event == fire) {
			if(item.ID=="ng") start_new_game(); else
			if(item.ID=="id_q") quit_game();
		} else
		if(event == change && item.ID=="id_rang") {
			set_player_lives(item.get());
		}
		// etc, and so on..
	});
	  
	add(menu);
	menu.goto("main"); // Goes to that page and opens the menu
	
	----------------------
	
== More examples on the (demo) project
	
*******************************************************************/

package djFlixel.ui;

import djA.DataT;
import djFlixel.core.Dtext.DTextStyle;
import djFlixel.ui.FlxAutoText;
import djFlixel.ui.UIDefaults;
import djFlixel.ui.menu.MIconCacher;
import djFlixel.ui.menu.MItem;
import djFlixel.ui.menu.MItemData;
import djFlixel.ui.menu.MPage;
import djFlixel.ui.menu.MPageData;
import djFlixel.ui.IListItem.ListItemEvent;
import flixel.FlxG;

import flixel.text.FlxText;
import flixel.group.FlxGroup;
import flixel.util.typeLimit.OneOfTwo;


// Menu Events that are sent to <FlxMenu.onMenuEvent>
// A <String> is also passed with that event
enum MenuEvent
{
	page;		// A page is shown | Par: The pageID that it changed to
	pageCall;	// A new page was requested from a link | Par: The pageID that got requested
	back;		// Went back, either by link or button | Par: The pageID that sent back
	close;		// Menu went off | Par: The pageID that was on before closing
	open;		// Menu went on | Par: The pageID that is displayed when opened
	rootback;	// Back button was pressed while on the first page of the menu (no more pages in history) | Par: null
	start;		// Start button was pressed | Par: The pageID start was pressed on
	focus;		// Menu was just focused | Par: pageID that got focused
	unfocus;	// Menu was just unfocused | Par: pageID that got unfocused
}


class FlxMenu extends FlxGroup
{
	public var x(default, null):Float;
	public var y(default, null):Float;
	
	public var isFocused(default, null):Bool = false;
	
	/** The PageData of the current Active Page */
	public var pageActive(default, null):MPageData;	
	
	/** FlxMenu can create pages with createPage(), it will store them here for quick retrieval */
	public var pages(default, null):Map<String,MPageData>;
	
	/** The Menu Page that is currently on screen,
	 *  if null then the menu is closed nothing is on screen */
	public var mpActive(default, null):MPage;
	
	/** Some functionality flags. Set these right after new() */
	public var PAR = {
		pool_max:4,					// How many MPages to keep in the pool
		enable_mouse:true,  		// Enable mouse interaction in general
		start_button_fire:false,	// True will make the start button fire to items
		page_anim_parallel:false,	// Page-on-off will run in parallel instead of waiting
		// --
		header_enable:true,			// Show an animated text title for each menu page
		header_offset_y:0,			// Offset Y position of the header
		header_CPS:18,				// Header Text, CPS for animation 0 for instant
		line_height:1,				// Decorative line color = stHeader.color
		line_time:0.4
	};
	
	/** If set will callback for menu Events | fn(MenuEvent, Page_ID) 
	 *  For more info check the <MenuEvent> typedef above */
	public var onMenuEvent:MenuEvent->String->Void;
	
	/** If set will callback for item Events | fn(ItemEvent, itemData) */
	public var onItemEvent:ListItemEvent->MItemData->Void;
	
	/** Page Style, used in all <MPages> 
	 *  For a guide checkout "UIDefaults.hx":MPAGE */
	public var STP:MPageStyle;
	
	/** Set the textstyle for the Header Text */
	public var stHeader:DTextStyle;
	
	// Stores the order of the Pages as they open
	// The last element of history is always the current page
	var history:Array<MPageData>;
	
	var pool:Array<MPage>;
	
	// An icon generator shared with all <MPage> objects
	var iconcache:MIconCacher;
	
	// Text Header
	var headerText:FlxAutoText;
	var decoLine:DecoLine;
	
	// HELPER. Used in goto();
	var __backreq:Bool = false;	
	
	// There are going to be passed to all created MPAGES
	var def_width:Int;
	var def_slots:Int;	
	
	/**
	   @param	X Screen X
	   @param	Y Screen Y
	   @param	WIDTH 0 To autocalculate based on item length (default) -1 Rest of screen, mirrored X Margin
	   @param	SLOTS How many vertical slots for items to show. If a menu has more items, it will scroll.
	**/
	public function new(X:Float=0, Y:Float=0, WIDTH:Int=0, SLOTS:Int = 6)
	{
		super();
		x = X; 
		y = Y;
		def_width = WIDTH; 
		def_slots = SLOTS;
		history = [];
		pages = [];
		pool = [];
		STP = DataT.copyDeep(UIDefaults.MPAGE);
	}//---------------------------------------------------;
	
	override public function destroy():Void 
	{
		if (iconcache != null) iconcache.clear();
		super.destroy();
		pool_clear();	// To destroy these objects as well
	}//---------------------------------------------------;
	
	
	/** Use this to overide whatever fields you want
	 *  to the main FlxMenu Style Object (STP)
	 *  Read "MPage.hx" <MPageStyle> for typedef info
	 */
	public function overlayStyle(st:Dynamic)
	{
		STP = DataT.copyFields(st, STP);
	}//---------------------------------------------------;
	
	
	/** This is a Quick Way to create and return a MenuPage 
	 *   plus it gets added to the FlxMenu pages DB */
	public function createPage(id:String, ?title:String):MPageData
	{
		var p = new MPageData(id, title);
		pages.set(id, p);
		return p;
	}//---------------------------------------------------;
	
	
	/**
	   If this was closed, restore the page and focus it
	   @param instant True will immediately show it with no animation
	**/
	public function open(instant:Bool = false)
	{
		if (pageActive == null)
		{
			trace("Error: No ActivePage set");
			return;
		}
		
		if (history.length == 0 || mpActive != null || isFocused) return;
		
		mpActive = pool_get(pageActive);
		add(mpActive);
		mpActive.viewOn(true, instant);	// > always focus the new page.
		headerText_show();
		
		//_mev(MenuEvent.focus, pageActive.ID); // DEV: Should it?
		_mev(MenuEvent.open, pageActive.ID);
		_mev(MenuEvent.page, pageActive.ID);	
		//  ^Redundant? However in some cases it is useful 
		//   When you need to sync another object visibility with a menu?
		//   Having only open it would need to listen to "open" and "page" events
		//   now it only has to listen to the "page" event
	}//---------------------------------------------------;
	
	/**
	   Close the active page. Restore it with open(). You can also goto()
	   @param	hard True will immediately hide it with no animation
	**/
	public function close(instant:Bool = false)
	{
		if (mpActive != null) // Close it
		{
			pool_put(mpActive);
			mpActive.viewOff((l)->remove(l), instant);
			mpActive = null;
			// DEV: Do not null pageActive, since it is read on open()
			
			//_mev(MenuEvent.unfocus, pageActive.ID); // DEV: Should it?
			_mev(MenuEvent.close, pageActive.ID);
		}
		
		isFocused = false;
		headerText_hide();
	}//---------------------------------------------------;
	
	/** Focus the Menu, gives keyboard focus, visual feedback */
	public function focus()
	{
		if (isFocused) return;
			isFocused = true;
		if (mpActive != null) {
			mpActive.focus();
		}
		_mev(MenuEvent.focus, pageActive.ID);
	}//---------------------------------------------------;
	
	/** Unfocus the Menu, removes keyboard focus, visual feedback */
	public function unfocus()
	{
		if (!isFocused) return;
			isFocused = false;
		if (mpActive != null) {
			mpActive.unfocus();
		}
		_mev(MenuEvent.unfocus, pageActive.ID);
	}//---------------------------------------------------;
	
	
	/**
	   Open a page and give it focus. Can goto an already created page
	   that was previously pushed to the pages Map with .createPage()/addPage
	   or you can give a new external PageData (e.g. on-the-fly create Pages with Dynamic Data)
	   @param _src  Page ID or Page Object
	   @param _open If it is closed, also open it the menu?
	**/
	public function goto(_src:OneOfTwo<String, MPageData>, _open:Bool = true)
	{
		var pdata:MPageData;
		if (Std.isOfType(_src, MPageData)) {
			pdata = cast _src;
		}else{
			pdata = pages.get(cast _src);
		}

		if (pdata == null) {
			FlxG.log.error("Could not get pagedata");
			return;
		}
	
		if (pageActive == pdata && _open) {
			// Already there, try to open the page and exit
			open();
			return;
		}
		
		// Search if this page is in history, if it is remove it and everything after it
		var i = history.length;
		while (i--> 0) {
			if (history[i] == pdata) {
				history.splice(i, history.length - i); // Remove from i to end
				break;
			}
		}
		
		pageActive = pdata;		
		history.push(pdata);
		
		if (!_open) return;
		
		isFocused = true;
		
		if (mpActive != null) // Close it
		{
			pool_put(mpActive);
			
			if (PAR.page_anim_parallel){
				mpActive.viewOff((l)->remove(l));
				_add_pageActive();
			}else{
				mpActive.viewOff((l)->{remove(l); _add_pageActive();});
			}
		}else{
			// This is the first call of goto(), so send a "open" event
			_mev(MenuEvent.open, pageActive.ID);
			_add_pageActive();
		}
		
	}//---------------------------------------------------;
	

	/** Go to the previous page in history */
	public function goBack()
	{
		// Can go back no more, notify user and return
		if (history.length <= 1) {
			_mev(rootback);
			return;
		}
		
		_mev(back, pageActive.ID);
		__backreq = true;	// goto() will try to restore the cursor to where it was
		history.pop(); 	// This is the current page on the history. Remove it.
		goto(history.pop()); // This is where I want to go
	}//---------------------------------------------------;
	
	
	/** Go to the furst page of the history queue,
	 * Useful when you are in a nested menu and want to go to the root */
	public function goHome()
	{
		if (history.length <= 1) return;
		__backreq = false;
		goto(history[0]);
	}//---------------------------------------------------;
	
	/**
	   Change an item's data or parameters e.g. (label, disabled)
	   The changes you make to the item will apply immediately on the menus
	   e.g.
			- Make the Second Item (index 1) toggle its disabled state
	   		menu.item_update(1, (i)->{i.disabled = !i.disabled;});
			
			- In Page "options" select item with id "audio" and set its range value to 0
			menu.item_update("options","audio", (i)->{i.data.c=0;});
			
		This function gets the item you need and passes it to a function, 
		so you must modify it from there. 
			
	   @param	pageID If Null will search the active page
	   @param	idOrIndex Item INDEX starting from 0 or ID
	   @param	modifyFN Alter the item in this function
	**/
	public function item_update(?pageID:String, idOrIndex:OneOfTwo<String,Int>, modifyFN:MItemData->Void)
	{
		// :: Get pagedata
		var pg:MPageData;
		if (pageID == null) pg = pageActive; else pg = pages.get(pageID);
		if (pg == null){
			trace('Error: Could not find pagedata $pageID');
			return;
		}
		
		// :: Get ItemData
		var item:MItemData;
		if (Std.isOfType(idOrIndex, String)){
			item = pg.get(cast idOrIndex);
		}else{
			item = pg.items[cast idOrIndex];
		}
		if (item == null){
			trace('item_update: Could not find Item in page', pg.ID, idOrIndex);
			return;
		}
		
		// :: User manipulation
		modifyFN(item);
		
		// -- Search created MPages for this page/item
		
		// :: Is it the active page.
		if (pg == pageActive)
		{
			mpActive.item_update(item);
			return;
		}
		
		// :: Search Pooled Pages
		for (p in pool)
		{
			if (p.page == pg)
			{
				p.item_update(item);
				return;
			}
		}
		
		// :: Not found anywhere,
		//    Do nothing, whenever a MPage will create the sprite, it will read the new data
			
	}//---------------------------------------------------;
	
	
	
	/** Automatically called, every time FlxMenu goes to a new Page 
		- creates or updates the Header Text (if enabled in PAR)
	*/
	function headerText_show()
	{
		if (!PAR.header_enable) return;
		
		if (headerText == null) // :: Create it
		{
			if (pageActive.title == null) return;	// No need to create it right now
			
			if (stHeader == null) {
				stHeader = {bt:2};	// outline style
			}
			stHeader.a = STP.align; // alignment always copies from list style
			
			if (stHeader.c == null) stHeader.c = STP.item.col_t.accent;
			if (stHeader.bc == null) stHeader.bc = STP.item.col_b.accent != null?STP.item.col_b.accent:STP.item.col_b.idle;

			headerText = new FlxAutoText(0, 0, mpActive.menu_width, 1);
			headerText.scrollFactor.set(0, 0);
			headerText.style = stHeader;
			headerText.setCPS(PAR.header_CPS);
			headerText.textObj.height; // HACK: Forces flxtext regen graphic to get proper height
			add(headerText);
			//--
			decoLine = new DecoLine(0, 0, mpActive.menu_width, PAR.line_height, STP.item.col_t.idle);
			decoLine.scrollFactor.set(0, 0);
			if (PAR.line_height > 0) // Hacky way to disable the line if you don't need it
				add(decoLine);
		}
		
		if (pageActive.title == null)
		{
			headerText.visible = decoLine.visible = false;
			return;
		}
		
		headerText.visible = decoLine.visible = true;
		headerText.setText(pageActive.title);
		
		headerText.x = x;
		headerText.y = y - (mpActive.overflows?STP.sind_size:0) - headerText.height + PAR.header_offset_y - PAR.line_height;
		decoLine.setPosition(x, headerText.y + headerText.height);
		decoLine.start(PAR.line_time);
	}//---------------------------------------------------;
	
	function headerText_hide()
	{
		if (!PAR.header_enable || headerText == null) return;
		headerText.visible = decoLine.visible = false;
	}//---------------------------------------------------;
	
	
	/** Called by MPage.onListEvent 
	 **/
	function on_list_event(msg:String)
	{
		if (msg == "back") {
			if (pageActive != null && pageActive.PAR.noBack) return;
			goBack(); 
		}
		else if (msg == "start")
		{
			_mev(start, pageActive.ID);
			return;
		}
	}//---------------------------------------------------;
	
	/** Called by MPage.onItemEvent 
	 **/
	function on_item_event(type:ListItemEvent, it:MItemData)
	{
		if (type == fire && it.type == link)
		{
			switch (it.P.ltype) {
				
				case 0:	// PageCall
					if (it.P.link == "back") {
						goBack(); 
					}else{
						_mev(pageCall, it.P.link);
						goto(it.P.link);
					}
					return;
				case 2:	// Call - Confirm Popup
					mpActive.active = false;
					D.ctrl.flush();	// <-- It is important to flush, otherwise it will register an input immediately after
					
					var P = MPageData.getConfirmationPage(it);
						P.PAR.stI = {text:DataT.copyFields(it.P.tStyle, Reflect.copy(STP.item.text))};
					
					var MP = pool_get(P);	// -> Will create a new page every time, because `noPool=true`
					
					var CLOSE_MP = ()->{
						D.ctrl.flush(); // prevent key firing again on the menu
						remove(MP);
						MP.destroy();
						mpActive.active = true;
						_mev(back);
					}
					MP.onListEvent = (a)-> { if (a == "back") CLOSE_MP(); };
					MP.onItemEvent = (ev, it2)-> {
						if (ev != fire) return;
						CLOSE_MP();
						if (it2.P.ltype == 1 && onItemEvent != null) onItemEvent(ev, it2); 
					};
					MP.x = mpActive.indexItem.x + mpActive.indexItem.width;
					MP.y = mpActive.indexItem.y;
					MP.setSelection(P.items.length - 1);	// Select last element, which is "NO"
					MP.focus();
					_mev(pageCall, "#confirmation");
					add(MP);
					return;
				case 3: // Call - Confirm New Page
					var P = MPageData.getConfirmationPage(it);
						P.PAR.stI = {text:DataT.copyFields(it.P.tStyle, Reflect.copy(STP.item.text))};
					goto(P);
					_mev(pageCall, "#confirmation");
					return;
				default: // This is normal call, do nothing, will be pushed to user 
			}
		}
		
		// Mirror the event to user
		if (onItemEvent != null) onItemEvent(type, it);
	}//---------------------------------------------------;

	

	// HELPER. sub - part of goto()
	// -
	function _add_pageActive()
	{
		mpActive = pool_get(pageActive);
		add(mpActive);
		mpActive.setPosition(x, y);			// in case the menu moved
		// : Get cursor position
		if (__backreq) {
			mpActive.setSelection(pageActive.PAR.lastIndex);
			__backreq = false;
		}else{
			mpActive.selectFirstAvailable();
		}
		mpActive.viewOn(true);	// > always focus the new page.
		headerText_show();
		_mev(MenuEvent.page, pageActive.ID);
	}//---------------------------------------------------;
	
	// DEV: This is the only onMenuEvent user callback caller
	// -
	function _mev(e:MenuEvent, ?d:String)
	{
		if (onMenuEvent != null) onMenuEvent(e, d);
	}//---------------------------------------------------;
	
	
	/** Tries to get from POOL, and if it can't 
		it will create a new MPage object and return that
	**/
	function pool_get(PD:MPageData):MPage
	{
		// - Does it exist in the pool?
		var p:MPage;
		for (i in 0...pool.length) {
			if (pool[i].page == PD){
				p = pool[i];
				pool.splice(i, 1);
				return p;
			}
		}
		
		// - Init iconcacher if it is not already
		if (iconcache == null) {
			iconcache = new MIconCacher(STP.item);
		}
		
		// - Create a new Page
		p = new MPage(x, y, def_width, def_slots);
		p.cameras = [camera];
		p.FLAGS.enable_mouse = PAR.enable_mouse;
		p.FLAGS.start_button_fire = PAR.start_button_fire;
		p.STP = STP;
		p.iconcache = iconcache;
		p.onItemEvent = on_item_event;
		p.onListEvent = on_list_event;
		p.setPage(PD);
		return p;		
	}//---------------------------------------------------;
	
	function pool_put(P:MPage)
	{
		if (P.page.PAR.noPool) return;
		if (pool.indexOf(P) >-1) return;
		// DEV: The page is guaranteed that does not exist in the pool since
		//      when it was created the pool was checked first.
		pool.push(P);
		if (pool.length > PAR.pool_max)
		{
			pool.shift().destroy();
		}
	}//---------------------------------------------------;
	
	function pool_clear()
	{
		if (pool != null) for (i in pool) i.destroy();
		pool = [];
	}//---------------------------------------------------;
	
	
}// -- end class
