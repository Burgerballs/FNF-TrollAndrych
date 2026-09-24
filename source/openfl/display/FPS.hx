package openfl.display;

import funkin.ClientPrefs;
import funkin.Paths;
import flixel.util.FlxStringUtil;
import openfl.text.Font;
import flixel.FlxG;
import flixel.math.FlxMath;

import openfl.text.TextField;
import external.memory.Memory;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.events.Event;
import haxe.Timer;

#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**Allows the FPS counter to lie about your framerate because Lime sucks and framerates goes above whats desired**/
	public var canLie:Bool = false;
	/** The current frame rate, expressed using frames-per-second **/
	public var currentFPS(default, null):Float = 0.0;
	/** The current state class name **/
	public var currentState(default, null):String = "";
	/** Whether to show a memory usage counter or not **/
	public var showMemory:Bool = #if final false #else true #end;

	public static var gcMemoryInBytes(get, never):Float;
	static function get_gcMemoryInBytes():Float return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public static var appMemoryInBytes(get, never):Float;
	static function get_appMemoryInBytes():Float return Memory.getCurrentUsage();

	public var align(default, set):TextFormatAlign;
	function set_align(val) {		
		return align = defaultTextFormat.align = switch (val){
			default: 
				this.x = 10;
				autoSize = LEFT;
				LEFT;

			case CENTER: 
				this.x = (this.stage.stageWidth - this.textWidth) * 0.5; 
				autoSize = CENTER;
				CENTER;

			case RIGHT: 
				this.x = (this.stage.stageWidth - this.textWidth) - 10; 
				autoSize = RIGHT;
				RIGHT;
		}
	}

	function onGameResized(windowWidth, ?windowHeight)
		align = align;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		this.background = true;
		this.backgroundColor = 0x000000;

		var textFormat = new TextFormat(null, 12, color);

		embedFonts = true;
		textFormat.font = 'Helvetica';
		defaultTextFormat = textFormat;


		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;

		multiline = true;
		text = "FPS: ";

		////
		addEventListener(Event.ADDED_TO_STAGE, (e:Event)->{
			if (align == null)
				align = #if mobile CENTER #else LEFT #end;
		});
		
		/*
		addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e)->{
			if (e.keyCode == flixel.input.keyboard.FlxKey.F3)
				this.align = switch (this.align){
					case LEFT: CENTER;
					case CENTER: RIGHT;
					case RIGHT: LEFT;
					default: LEFT;
				}
		});
		*/

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e){
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end

		FlxG.signals.gameResized.add(onGameResized);

		#if (debug && false)
		FlxG.signals.preStateCreate.add((nextState)->{
			currentState = Type.getClassName(Type.getClass(nextState));
		});
		#end
	}


	var balls:Int = 0;
	var lastRefreshTime:Float = 0;
	var elapsedTime:Float = 0;
	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		alpha = ClientPrefs.fpsOpacity;
		background = ClientPrefs.fpsBG;
		elapsedTime += deltaTime;

		balls++;

		while (lastRefreshTime < elapsedTime - 1000)
		{
			var currentCount = balls;
			currentFPS = balls;


			generateFpsText();

			#if (debug && false)
			text += '\nState: $currentState';
			#end

			if (currentFPS <= FlxG.drawFramerate * 0.5 && !ClientPrefs.unlimited)
				textColor = 0xFFFF0000;
			else
				textColor = 0xFFFFFFFF;

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end
			balls = 0;
				lastRefreshTime = elapsedTime;
		}
	}

	private inline function generateFpsText() {
		switch (ClientPrefs.fpsStyle) {
			case 'Funkin' | 'Psych':
				text = 'FPS: $currentFPS';
				if (showMemory) // Credit to Rudyrue and Leather128 for this one
					text += ' \nMemory: ${FlxStringUtil.formatBytes(gcMemoryInBytes)}';
			default:
				text = 'FPS: $currentFPS';
			
				if (showMemory) // Credit to Rudyrue and Leather128 for this one
					text += ' • Memory: ${FlxStringUtil.formatBytes(gcMemoryInBytes)}';
		}
	}
}
