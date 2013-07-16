package ui 
{
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.GraphicsPath;
	import flash.display.GraphicsSolidFill;
	import flash.display.GraphicsStroke;
	import flash.display.IGraphicsData;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.ContextMenu;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import SfxrApp;
	
	/**
	 * ...
	 * @author Mark Wonnacott
	 */
	public class Individual extends Sprite
	{
		protected var _app:SfxrApp;
		protected var _synth:SfxrSynth;
		
		protected var _play:TinyButton;
		protected var _select:TinyButton;
		protected var _save:TinyButton;
		protected var _export:TinyButton;
		
		protected var _enabled:Boolean;
		
		public function get params():SfxrParams { return _synth.params.clone(); }
		public function set params(params:SfxrParams):void
		{
			_synth.params = params.clone();
		}
		
		public function get selected():Boolean { return _select.selected; }
		
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(v:Boolean):void
		{
			_enabled = v;
			
			_play.enabled   = _enabled;
			_select.enabled = _enabled;
			_save.enabled   = _enabled;
			_export.enabled = _enabled;
			
			_select.selected = false;
		}
		
		public function Individual(app:SfxrApp, x:int, y:int)
		{
			_app = app;
			
			_synth = new SfxrSynth();
			_synth.params.randomize();
			_synth.params.waveType = 0;
			
			_play = new TinyButton(this.play, "PLAY", 1, false, 104, 60);
			_play.x = x + 3;
			_play.y = y + 3;
			addChild(_play);
			
			_select = new TinyButton(this.select, "SELECT", 1, true);
			_select.x = x + 3;
			_select.y = y + 3 + 104 - 18 - 22;
			addChild(_select);
			
			var fitness:TinySlider = new TinySlider(this.play, "", false, 104, 18, 4);
			fitness.x = x + 3;
			fitness.y = y + 3 + 104-18-22;
			//addChild(fitness);
			
			_save = new TinyButton(this.save, ".SFS", 1, false, 50);
			_save.x = x + 3;
			_save.y = y + 3 + 104 - 18;
			addChild(_save);
			
			_export = new TinyButton(this.export, ".WAV", 1, false, 50);
			_export.x = x + 3 + 54;
			_export.y = y + 3 + 104 - 18;
			addChild(_export);
		}
		
		protected function play(button:TinyButton):void
		{
			_synth.play();
		}
		
		protected function select(button:TinyButton):void
		{
			//_synth.play();
		}
		
		protected function save(button:TinyButton):void
		{
			var file:ByteArray = _app.getSettingsFile(_synth);
			new FileReference().save(file, "sfx.sfs");
		}
		
		protected function export(button:TinyButton):void
		{
			var file:ByteArray = _synth.getWavFile(44100, 16);
			new FileReference().save(file, "sfx.wav");
		}
	}
}