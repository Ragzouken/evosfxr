package ui 
{
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.GraphicsPath;
	import flash.display.GraphicsSolidFill;
	import flash.display.GraphicsStroke;
	import flash.display.GraphicsPathCommand;
	import flash.display.IGraphicsData;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Shader;
	import flash.display.Shape;
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
		protected var _graphic:Visualisation;
		protected var _select:TinyButton;
		protected var _save:TinyButton;
		protected var _export:TinyButton;
		
		protected var _enabled:Boolean;
		
		public function get params():SfxrParams { return _synth.params.clone(); }
		public function set params(params:SfxrParams):void
		{
			_synth.params = params.clone();
			
			_graphic.refresh(_synth.params);
		}
		
		public function get selected():Boolean { return _select.selected; }
		
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void
		{
			_enabled = value;
			
			_play.enabled    = _enabled;
			_graphic.enabled = _enabled;
			_select.enabled  = _enabled;
			_save.enabled    = _enabled;
			_export.enabled  = _enabled;
			
			_select.selected = false;
			
			if(value) 	_graphic.alpha = 1.0;
			else		_graphic.alpha = 0.3;
		}
		
		public function Individual(app:SfxrApp, x:int, y:int, params:SfxrParams)
		{
			_app = app;
			
			_synth = new SfxrSynth();
			_synth.params = params;
			//_synth.params.masterVolume = 0;
			
			_play = new TinyButton(this.play, "PLAY", 1, false, 104, 60);
			_play.x = x + 3;
			_play.y = y + 3;
			addChild(_play);
			
			_graphic = new Visualisation(x + 110 / 2, y + 60 / 2, _synth.params);
			addChild(_graphic);
			
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