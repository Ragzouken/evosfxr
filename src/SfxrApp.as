﻿package  
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
	import ui.TinyButton;
	import ui.TinyCheckbox;
	import ui.TinySlider;
	import ui.Individual;
	import ui.Visualisation;

	/**
	 * SfxrApp
	 * 
	 * Copyright 2013 Mark Wonnacott
	 *
	 * This derivative work is a modification of the original file whose
	 * copyright and attribution is available below.
	 * 
	 * Licensed under the Apache License, Version 2.0 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 *
	 * 	http://www.apache.org/licenses/LICENSE-2.0
	 *
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 * 
	 * @author Mark Wonnacott
	 */
	
	// ORIGINAL COPYRIGHT NOTICE & ATTRIBUTION
	/**
	 * SfxrApp
	 * 
	 * Copyright 2010 Thomas Vian
	 *
	 * Licensed under the Apache License, Version 2.0 (the "License");
	 * you may not use this file except in compliance with the License.
	 * You may obtain a copy of the License at
	 *
	 * 	http://www.apache.org/licenses/LICENSE-2.0
	 *
	 * Unless required by applicable law or agreed to in writing, software
	 * distributed under the License is distributed on an "AS IS" BASIS,
	 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 * See the License for the specific language governing permissions and
	 * limitations under the License.
	 */
	
	[SWF(width='640', height='527', backgroundColor='#C0B090', frameRate='25')]
	public class SfxrApp extends Sprite
	{
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		[Embed(source = "assets/amiga4ever.ttf", fontName = "Amiga4Ever", mimeType = "application/x-font", embedAsCFF = "false")]
		private var Amiga4Ever:Class;				// Pixel font, original was in a tga file
		
		private var _sampleRate:uint = 44100;		// Sample rate to export .wav at
		private var _bitDepth:uint = 16;			// Bit depth to export .wav at
		
		private var _playOnChange:Boolean = true;	// If the sound should be played after releasing a slider or changing type
		private var _mutePlayOnChange:Boolean;		// If the change playing should be muted because of non-user changes
		
		private var _propLookup:Dictionary;			// Look up for property names using a slider key
		private var _sliderLookup:Object;			// Look up for sliders using a property name key
		private var _waveformLookup:Array;			// Look up for waveform buttons
		private var _squareLookup:Array;			// Look up for sliders controlling a square wave property
		
		private var _back:TinyButton;				// Button to skip back a sound
		private var _forward:TinyButton;			// Button to skip forward a sound
		private var _history:Vector.<SfxrParams>;	// List of generated settings
		private var _historyPos:int;				// Current history position
		
		private var _copyPaste:TextField;			// Input TextField for the settings
		
		private var _fileRef:FileReference;			// File reference for loading in sfs file
		
		private var _logoRect:Rectangle;			// Click rectangle for SFB website link
		private var _sfxrRect:Rectangle;			// Click rectangle for LD website link
		private var _volumeRect:Rectangle;			// Click rectangle for resetting volume
		
		private var _synthL:SfxrSynth;
		private var _synthC:SfxrSynth;
		private var _synthR:SfxrSynth;
		private var _synthS:SfxrSynth;
		
		private var _individuals:Vector.<Individual>;
		private var _confirmSelection:TinyButton;
		private var _sweeper:TinySlider;
		private var _confirmCrossover:TinyButton;
		
		private var _selected:Vector.<SfxrParams>;
		private var _crossover:Vector.<SfxrParams>;
		private var _recombined:Vector.<SfxrParams>;
		
		private var _sweepVis:Visualisation;
		
		//--------------------------------------------------------------------------
		//	
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Waits until on the stage before init
		 */
		public function SfxrApp() 
		{
			if (stage) 	init();
			else 		addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Init Method
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Initialises the synthesizer and draws the interface
		 * @param	e	Added to stage event
		 */
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			_propLookup = new Dictionary();
			_sliderLookup = {};
			_waveformLookup = [];
			_squareLookup = [];
			
			_history = new Vector.<SfxrParams>();
			//_history.push(_synthS.params);
			
			setupSweeper();
			drawCopyPaste();
			
			updateSliders();
			updateCopyPaste();
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Button Methods
		//
		//--------------------------------------------------------------------------
		
		private function setupSweeper():void
		{
			_synthL = new SfxrSynth();
			_synthR = new SfxrSynth();
			_synthS = new SfxrSynth();
			
			_synthL.params.randomize();
			_synthR.params.randomize();
			
			_synthL.params.waveType = 0;
			_synthR.params.waveType = 0;
			
			_synthS.params = _synthL.params.clone();
			
			_selected = new Vector.<SfxrParams>();
			_crossover = new Vector.<SfxrParams>();
			_recombined = new Vector.<SfxrParams>();
			
			var width:int  = 640;
			var height:int = 160;
			
			var sweeperWidth:int = width - 8 - 104;
			
			var topRowY:int = 23 + 320;
			var spacing:int = (sweeperWidth - 110 * 4) / 3 + 110;
			var offset:int = (width - sweeperWidth) / 2;
			
			generatePopulation();
			
			_individuals = new Vector.<Individual>();
			
			for (var y:int = 0; y < 2; ++y) {
				for (var x:int = 0; x < 4; ++x) {
					var config:SfxrParams = _recombined.pop();
					var individual:Individual = new Individual(this, x * spacing + offset, y * spacing + offset, config);
					_individuals.push(individual);
					addChild(individual);
				}
			}
			
			assessDiversity();
			
			_confirmSelection = addButton("CONFIRM", selectionConfirmed, width/2 - 52, spacing + offset + 110 + 18);
			
			var divide:int = spacing + 110 + offset * 2;
			
			var lines:Vector.<IGraphicsData> = new Vector.<IGraphicsData>();
			lines.push(new GraphicsStroke(1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 3, new GraphicsSolidFill(0)));
			lines.push(new GraphicsPath(Vector.<int>([1,2]), 
										Vector.<Number>([0, divide, width, divide])));
			graphics.drawGraphicsData(lines);
			
			_sweeper = new TinySlider(onSweeperChange, "", false, sweeperWidth, 54);
			_sweeper.x = (width - sweeperWidth) / 2;
			_sweeper.y = divide + (width - sweeperWidth) / 2;
			addChild(_sweeper);
			_sweeper.enabled = false;
			
			_sweepVis = new Visualisation(_sweeper.x + sweeperWidth / 2, _sweeper.y + 54/2, _synthS.params);
			addChild(_sweepVis);
			_sweepVis.enabled = false;
			
			_confirmCrossover = addButton("SELECT CHILD", childSelected, width/2 - 52, divide + (width - sweeperWidth) / 2 + 54 + 19);
			_confirmCrossover.enabled = false;
			
			//addSlider("", "masterVolume", width/2 + offset - 50, topRowY + 30 + 54 + 7 + 30);
			//graphics.lineStyle(2, 0xFF0000, 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE, JointStyle.MITER);
			//graphics.drawRect(width/2-0.5 + offset + 50 - 42, topRowY+54+30+7+30-0.5, 43, 10);
			
			addLabel("SELECTION",        offset,      0, 0x504030);
			addLabel("MANUAL CROSSOVER", offset, divide, 0x504030);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void {
				if (!_confirmCrossover.enabled) { return; }
				
				switch (e.keyCode) {
					case Keyboard.LEFT:
						_sweeper.value = Math.round((_sweeper.value - 0.1)*10) / 10;
						break;
					case Keyboard.RIGHT:
						_sweeper.value = Math.round((_sweeper.value + 0.1)*10) / 10;
						break;
					case Keyboard.SPACE:
					case Keyboard.UP:
						_synthS.play();
						break;
					case Keyboard.ENTER:
					case Keyboard.DOWN:
						childSelected(null);
						break;
				}
			});
		}
		
		private function generatePopulation():void
		{
			var bound:Number = 0.35;
			
			while (_recombined.length != 8) {
				var config:SfxrParams = new SfxrParams();
				var min:Number = 0;
				
				while (min < bound) {
					config.randomize();
					config.waveType = 0;
					
					min = 1;
					
					for each (var other:SfxrParams in _recombined) {
						var distance:Number = config.distance(other);
						min = Math.min(min, distance);
					}
				}
				
				_recombined.push(config);
			}
		}
		
		private function assessDiversity():void
		{
			var distances:Vector.<Number> = new Vector.<Number>();
			var sum:Number = 0;
			
			var min:Number = 1;
			for (var i:int = 0; i < 8; ++i) {
				for (var j:int = i+1; j < 8; ++j) {
					var distance:Number = _individuals[i].params.distance(_individuals[j].params)
					distances.push(distance);
					sum += distance;
					
					min = Math.min(min, distance);
				}
			}
			
			trace("min: " + min + " avg: " + (sum / distances.length));
		}
		
		private function childSelected(button:TinyButton):void
		{
			_recombined.push(_synthS.params.clone());
			
			if (_crossover.length > 0) {
				switchToCrossover();
			} else {
				switchToSelection();
			}
		}
		
		private function selectionConfirmed(button:TinyButton):void
		{
			_crossover.length = 0;
			_recombined.length = 0;
			
			for each (var individual:Individual in _individuals) {
				if (individual.selected) {
					_selected.push(individual.params);
				}
			}
			
			if (_selected.length > 1) {
				var pairings:Dictionary = new Dictionary();
			
				for each (var parent:SfxrParams in _selected) {
					pairings[parent] = new Vector.<SfxrParams>();
				}
				
				for each (var parent:SfxrParams in _selected) {
					if (_selected.length > pairings[parent].length + 1) {
						var mate:SfxrParams = parent;
						
						while (mate === parent || pairings[mate].indexOf(parent) >= 0) {
							mate = _selected[Math.floor(_selected.length * Math.random())];
						}
						
						pairings[parent].push(mate);
						pairings[mate].push(parent);
						
						_crossover.push(parent.clone());
						_crossover.push(mate.clone());
					}
				}
			}
			
			while (_crossover.length / 2 < 4) {
				var base:SfxrParams = _selected[Math.floor(_selected.length * Math.random())];
				var other:SfxrParams = new SfxrParams();
				other.randomize();
				other.waveType = 0;
				
				_crossover.push(base.clone());
				_crossover.push(other);
			}
			
			_selected.length = 0;
			
			// switch to cross over to perform remaining crossover
			if (_crossover.length > 0) {
				switchToCrossover();
			} else {
				switchToSelection();
			}
		}
		
		private function switchToCrossover():void
		{
			_synthL.params = _crossover.pop();
			_synthR.params = _crossover.pop();
			
			for each (var individual:Individual in _individuals) {
				individual.enabled = false;
			}
			
			_confirmSelection.enabled = false;
			
			_sweeper.enabled = true;
			_sweeper.value = 0.5;
			_sweepVis.enabled = true;
			_confirmCrossover.enabled = true;
		}
		
		private function switchToSelection():void
		{
			generatePopulation();
			
			for (var i:int = 0; i < 8; ++i) {
				_individuals[i].params = _recombined[i];
			}
			
			_recombined.length = 0;
			
			for each (var individual:Individual in _individuals) {
				individual.enabled = true;
			}
			
			_confirmSelection.enabled = true;
			
			_sweeper.enabled = false;
			_sweepVis.enabled = false;
			_confirmCrossover.enabled = false;
			
			assessDiversity();
		}
		
		private function clickLoadFactory(synth:SfxrSynth):Function
		{
			var click:Function;
			var select:Function;
			var load:Function;
			
			click = function(button:TinyButton):void {
				_fileRef = new FileReference();
				_fileRef.addEventListener(Event.SELECT, select);
				_fileRef.browse([new FileFilter("SFX Sample Files (*.sfs)", "*.sfs")]);
			}
			
			select = function(e:Event):void {
				_fileRef.cancel();
			
				_fileRef.removeEventListener(Event.SELECT, select);
				_fileRef.addEventListener(Event.COMPLETE, load);
				_fileRef.load();
			};
			
			load = function(e:Event):void {
				_fileRef.removeEventListener(Event.COMPLETE, load);
			
				//addToHistory();
				setSettingsFile(_fileRef.data, synth);
				//updateSliders();
				updateCopyPaste();
				
				_fileRef = null;
			};
			
			return click;
		}
		
		private function mix(left:Number, right:Number, u:Number):Number
		{
			return left * (1 - u) + right * u;
		}
		
		private function interpolate(child:SfxrParams, left:SfxrParams, right:SfxrParams, u:Number):void
		{
			child.masterVolume = mix(left.masterVolume, right.masterVolume, u);
			
			child.attackTime   = mix(left.attackTime,   right.attackTime,   u);
			child.sustainTime  = mix(left.sustainTime,  right.sustainTime,  u);
			child.sustainPunch = mix(left.sustainPunch, right.sustainPunch, u);
			child.decayTime    = mix(left.decayTime,    right.decayTime,    u);
			
			child.startFrequency = mix(left.startFrequency, right.startFrequency, u);
			child.minFrequency   = mix(left.minFrequency,   right.minFrequency,   u);
			
			child.slide      = mix(left.slide,      right.slide,      u);
			child.deltaSlide = mix(left.deltaSlide, right.deltaSlide, u);
			
			child.vibratoDepth = mix(left.vibratoDepth, right.vibratoDepth, u);
			child.vibratoSpeed = mix(left.vibratoSpeed, right.vibratoSpeed, u);
			
			child.changeAmount = mix(left.changeAmount, right.changeAmount, u);
			child.changeSpeed  = mix(left.changeSpeed,  right.changeSpeed,  u);
			
			child.squareDuty = mix(left.squareDuty, right.squareDuty, u);
			child.dutySweep  = mix(left.dutySweep,  right.dutySweep,  u);
			
			child.repeatSpeed = mix(left.repeatSpeed, right.repeatSpeed, u);
			
			child.phaserOffset = mix(left.phaserOffset, right.phaserOffset, u);
			child.phaserSweep  = mix(left.phaserSweep,  right.phaserSweep,  u);
			
			child.lpFilterCutoff      = mix(left.lpFilterCutoff,      right.lpFilterCutoff,      u);
			child.lpFilterCutoffSweep = mix(left.lpFilterCutoffSweep, right.lpFilterCutoffSweep, u);
			child.lpFilterResonance   = mix(left.lpFilterResonance,   right.lpFilterResonance,   u);
			
			child.hpFilterCutoff      = mix(left.hpFilterCutoff,      right.hpFilterCutoff,      u);
			child.hpFilterCutoffSweep = mix(left.hpFilterCutoffSweep, right.hpFilterCutoffSweep, u);
		}
		
		private function cross(child:SfxrParams, left:SfxrParams, right:SfxrParams, u:Vector.<Number>):void
		{
			//child.masterVolume = _synth.params.masterVolume; //mix(left.masterVolume, right.masterVolume, u);
			
			child.attackTime   = mix(left.attackTime,   right.attackTime,   u[0]);
			child.sustainTime  = mix(left.sustainTime,  right.sustainTime,  u[1]);
			child.sustainPunch = mix(left.sustainPunch, right.sustainPunch, u[2]);
			child.decayTime    = mix(left.decayTime,    right.decayTime,    u[3]);
			
			child.startFrequency = mix(left.startFrequency, right.startFrequency, u[4]);
			child.minFrequency   = mix(left.minFrequency,   right.minFrequency,   u[5]);
			
			child.slide      = mix(left.slide,      right.slide,      u[6]);
			child.deltaSlide = mix(left.deltaSlide, right.deltaSlide, u[7]);
			
			child.vibratoDepth = mix(left.vibratoDepth, right.vibratoDepth, u[8]);
			child.vibratoSpeed = mix(left.vibratoSpeed, right.vibratoSpeed, u[9]);
			
			child.changeAmount = mix(left.changeAmount, right.changeAmount, u[10]);
			child.changeSpeed  = mix(left.changeSpeed,  right.changeSpeed,  u[11]);
			
			child.squareDuty = mix(left.squareDuty, right.squareDuty, u[12]);
			child.dutySweep  = mix(left.dutySweep,  right.dutySweep,  u[13]);
			
			child.repeatSpeed = mix(left.repeatSpeed, right.repeatSpeed, u[14]);
			
			child.phaserOffset = mix(left.phaserOffset, right.phaserOffset, u[15]);
			child.phaserSweep  = mix(left.phaserSweep,  right.phaserSweep,  u[16]);
			
			child.lpFilterCutoff      = mix(left.lpFilterCutoff,      right.lpFilterCutoff,      u[17]);
			child.lpFilterCutoffSweep = mix(left.lpFilterCutoffSweep, right.lpFilterCutoffSweep, u[18]);
			child.lpFilterResonance   = mix(left.lpFilterResonance,   right.lpFilterResonance,   u[19]);
			
			child.hpFilterCutoff      = mix(left.hpFilterCutoff,      right.hpFilterCutoff,      u[20]);
			child.hpFilterCutoffSweep = mix(left.hpFilterCutoffSweep, right.hpFilterCutoffSweep, u[21]);
		}
		
		/**
		 * Updates the swept parameters to match the interpolation.
		 * @param	sweeper
		 */
		private function onSweeperChange(sweeper:TinySlider):void
		{
			interpolate(_synthS.params, _synthL.params, _synthR.params, sweeper.value);
			
			_synthS.play();
			
			updateSliders();
			updateCopyPaste();
			
			_sweepVis.refresh(_synthS.params);
		}
		
		/**
		 * Adds a single button
		 * @param	label			Text to display on the button
		 * @param	onClick			Callback function called when the button is clicked
		 * @param	x				X position of the button
		 * @param	y				Y position of the button
		 * @param	border			Thickness of the border in pixels
		 * @param	selectable		If the button is selectable
		 * @param	selected		If the button starts as selected
		 */
		private function addButton(label:String, onClick:Function, x:Number, y:Number, selectable:Boolean = false, width:int = 104, height:int = 18):TinyButton
		{
			var button:TinyButton = new TinyButton(onClick, label, 1, selectable, width, height);
			button.x = x;
			button.y = y;
			addChild(button);
			
			if(selectable) _waveformLookup.push(button);
			
			return button;
		}
		
		//--------------------------------------------------------------------------
		//	
		//  History Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * When the back button is clicked, moves back through the history
		 * @param	button	TinyButton clicked
		 */
		private function clickBack(button:TinyButton):void
		{
			_historyPos--;
			if(_historyPos == 0) 					_back.enabled = false;
			if(_historyPos < _history.length - 1) 	_forward.enabled = true;
			
			//_synth.stop();
			//_synth.params = _history[_historyPos];
			
			updateSliders();
			updateCopyPaste();
			
			//_synth.play();
		}
		
		/**
		 * When the forward button is clicked, moves forward through the history
		 * @param	button	TinyButton clicked
		 */
		private function clickForward(button:TinyButton):void
		{
			_historyPos++;
			if(_historyPos > 0) 					_back.enabled = true;
			if(_historyPos == _history.length - 1) 	_forward.enabled = false;
			
			//_synth.stop();
			//_synth.params = _history[_historyPos];
			
			updateSliders();
			updateCopyPaste();
			
			//_synth.play();
		}
		
		/**
		 * Adds a new sound effect to the history. 
		 * Called just before a new sound effect is generated.
		 */
		private function addToHistory():void
		{
			_historyPos++;
			//_synth.params = _synth.params.clone();
			_history = _history.slice(0, _historyPos);
			//_history.push(_synth.params);
			
			_back.enabled = true;
			_forward.enabled = false;
		}   
		
		//--------------------------------------------------------------------------
		//	
		//  Play/Save/Export Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Opens a browse window to load a sound setting file
		 * @param	button	Button pressed
		 */
		private function clickLoadSound(button:TinyButton):void
		{
			_fileRef = new FileReference();
			_fileRef.addEventListener(Event.SELECT, onSelectSettings);
			_fileRef.browse([new FileFilter("SFX Sample Files (*.sfs)", "*.sfs")]);
		}
		
		/**
		 * When the user selects a file, begins loading it
		 * @param	e	Select event
		 */
		private function onSelectSettings(e:Event):void
		{
			_fileRef.cancel();
			
			_fileRef.removeEventListener(Event.SELECT, onSelectSettings);
			_fileRef.addEventListener(Event.COMPLETE, onLoadSettings);
			_fileRef.load();
		}
		
		/**
		 * Once loaded, passes the file to the synthesizer to parse
		 * @param	e	Complete event
		 */
		private function onLoadSettings(e:Event):void
		{
			_fileRef.removeEventListener(Event.COMPLETE, onLoadSettings);
			
			addToHistory();
			setSettingsFile(_fileRef.data);
			updateSliders();
			updateCopyPaste();
			
			_fileRef = null;
		}
		
		/**
		 * Switches the sample rate between 44100Hz and 22050Hz 
		 * @param	button	Button pressed
		 */
		private function clickSampleRate(button:TinyButton):void
		{
			if(_sampleRate == 44100) 	_sampleRate = 22050;
			else 						_sampleRate = 44100;
			
			button.label = _sampleRate + " HZ";
		}
		
		/**
		 * Switches the bit depth between 16-bit and 8-bit
		 * @param	button	Button pressed
		 */
		private function clickBitDepth(button:TinyButton):void
		{
			if(_bitDepth == 16) _bitDepth = 8;
			else 				_bitDepth = 16;
			
			button.label = _bitDepth + "-BIT";
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Settings File Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Writes the current parameters to a ByteArray and returns it
		 * Compatible with the original Sfxr files
		 * @return	ByteArray of settings data
		 */
		public function getSettingsFile(synth:SfxrSynth):ByteArray
		{
			var file:ByteArray = new ByteArray();
			file.endian = Endian.LITTLE_ENDIAN;
			
			file.writeInt(102);
			file.writeInt(synth.params.waveType);
			file.writeFloat(synth.params.masterVolume);
			
			file.writeFloat(synth.params.startFrequency);
			file.writeFloat(synth.params.minFrequency);
			file.writeFloat(synth.params.slide);
			file.writeFloat(synth.params.deltaSlide);
			file.writeFloat(synth.params.squareDuty);
			file.writeFloat(synth.params.dutySweep);
			
			file.writeFloat(synth.params.vibratoDepth);
			file.writeFloat(synth.params.vibratoSpeed);
			file.writeFloat(0);
			
			file.writeFloat(synth.params.attackTime);
			file.writeFloat(synth.params.sustainTime);
			file.writeFloat(synth.params.decayTime);
			file.writeFloat(synth.params.sustainPunch);
			
			file.writeBoolean(false);
			file.writeFloat(synth.params.lpFilterResonance);
			file.writeFloat(synth.params.lpFilterCutoff);
			file.writeFloat(synth.params.lpFilterCutoffSweep);
			file.writeFloat(synth.params.hpFilterCutoff);
			file.writeFloat(synth.params.hpFilterCutoffSweep);
			
			file.writeFloat(synth.params.phaserOffset);
			file.writeFloat(synth.params.phaserSweep);
			
			file.writeFloat(synth.params.repeatSpeed);
			
			file.writeFloat(synth.params.changeSpeed);
			file.writeFloat(synth.params.changeAmount);
			
			return file;
		}
		
		/**
		 * Reads parameters from a ByteArray file
		 * Compatible with the original Sfxr files
		 * @param	file	ByteArray of settings data
		 */
		public function setSettingsFile(file:ByteArray, synth:SfxrSynth = null):void
		{	
			file.position = 0;
			file.endian = Endian.LITTLE_ENDIAN;
			
			var version:int = file.readInt();
			
			if(version != 100 && version != 101 && version != 102) return;
			
			synth.params.waveType = file.readInt();
			synth.params.masterVolume = (version == 102) ? file.readFloat() : 0.5;
			
			synth.params.startFrequency = file.readFloat();
			synth.params.minFrequency = file.readFloat();
			synth.params.slide = file.readFloat();
			synth.params.deltaSlide = (version >= 101) ? file.readFloat() : 0.0;
			
			synth.params.squareDuty = file.readFloat();
			synth.params.dutySweep = file.readFloat();
			
			synth.params.vibratoDepth = file.readFloat();
			synth.params.vibratoSpeed = file.readFloat();
			var unusedVibratoDelay:Number = file.readFloat();
			
			synth.params.attackTime = file.readFloat();
			synth.params.sustainTime = file.readFloat();
			synth.params.decayTime = file.readFloat();
			synth.params.sustainPunch = file.readFloat();
			
			var unusedFilterOn:Boolean = file.readBoolean();
			synth.params.lpFilterResonance = file.readFloat();
			synth.params.lpFilterCutoff = file.readFloat();
			synth.params.lpFilterCutoffSweep = file.readFloat();
			synth.params.hpFilterCutoff = file.readFloat();
			synth.params.hpFilterCutoffSweep = file.readFloat();
			
			synth.params.phaserOffset = file.readFloat();
			synth.params.phaserSweep = file.readFloat();
			
			synth.params.repeatSpeed = file.readFloat();
			
			synth.params.changeSpeed = (version >= 101) ? file.readFloat() : 0.0;
			synth.params.changeAmount = (version >= 101) ? file.readFloat() : 0.0;
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Slider Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Adds a single slider
		 * @param	label			Text label to display next to the slider
		 * @param	property		Property name to link with the slider
		 * @param	x				X position of slider
		 * @param	y				Y Position of slider
		 * @param	plusMinus		If the slider ranges from -1 to 1 (true) or 0 to 1 (false)
		 * @param	square			If the slider is linked to the square duty properties
		 */
		private function addSlider(label:String, property:String, x:Number, y:Number, plusMinus:Boolean = false, square:Boolean = false):TinySlider
		{
			var slider:TinySlider = new TinySlider(onSliderChange, label, plusMinus);
			slider.x = x;
			slider.y = y;
			addChild(slider);
			
			_propLookup[slider] = property;
			_sliderLookup[property] = slider;
			
			if (square) _squareLookup.push(slider);
			
			return slider;
		}
		
		/**
		 * Updates the property on the synthesizer to the slider's value
		 * @param	slider
		 */
		private function onSliderChange(slider:TinySlider):void
		{
			_synthS.params[_propLookup[slider]] = slider.value;
			
			updateCopyPaste();
			
			if (_playOnChange && !_mutePlayOnChange) _synthS.play();
		}
		
		/**
		 * Updates the sliders to reflect the synthesizer
		 */
		private function updateSliders():void
		{
			_mutePlayOnChange = true;
			
			for(var prop:String in _sliderLookup)
			{
				_sliderLookup[prop].value = _synthS.params[prop];
			}
			
			_mutePlayOnChange = false;
		}
		
		/**
		 * Changes if the sound should play on params change
		 * @param	checkbox	Checbox clicked
		 */
		private function onCheckboxChange(checkbox:TinyCheckbox):void
		{
			_playOnChange = checkbox.value;
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Copy Paste Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Adds a TextField over the whole app. 
		 * Allows for right-click copy/paste, as well as ctrl-c/ctrl-v
		 */
		private function drawCopyPaste():void
		{
			_copyPaste = new TextField();
			_copyPaste.addEventListener(TextEvent.TEXT_INPUT, updateFromCopyPaste);
			_copyPaste.addEventListener(KeyboardEvent.KEY_DOWN, updateCopyPaste);
			_copyPaste.addEventListener(KeyboardEvent.KEY_UP, updateCopyPaste);
			_copyPaste.defaultTextFormat = new TextFormat("Amiga4Ever", 8, 0);
			_copyPaste.wordWrap = false;
			_copyPaste.multiline = false;
			_copyPaste.type = TextFieldType.INPUT;
			_copyPaste.embedFonts = true;
			_copyPaste.width = 640;
			_copyPaste.height = 180;
			_copyPaste.x = 0;
			_copyPaste.y = -20;
			addChild(_copyPaste);
			
			_copyPaste.contextMenu = new ContextMenu();
			_copyPaste.contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, updateCopyPaste);
			
			Mouse.cursor = MouseCursor.ARROW;
		}
		
		/**
		 * Updates the contents of the textfield to a representation of the settings
		 * @param	e	Optional event
		 */
		private function updateCopyPaste(e:Event = null):void
		{
			_copyPaste.text = _synthS.params.getSettingsString();
			
			_copyPaste.setSelection(0, _copyPaste.text.length);
			stage.focus = _copyPaste;
		}
		
		/**
		 * When the textfield is pasted into, and the new info parses, updates the settings
		 * @param	e	Text input event
		 */
		private function updateFromCopyPaste(e:TextEvent):void
		{
			if (e.text.split(",").length == 24) addToHistory();
			
			if (!_synthS.params.setSettingsString(e.text)) 
			{
				_copyPaste.setSelection(0, _copyPaste.text.length);
				stage.focus = _copyPaste;
				
				_copyPaste.text = _synthS.params.getSettingsString();
			}
			
			_copyPaste.setSelection(0, _copyPaste.text.length);
			stage.focus = _copyPaste;
			
			updateSliders();
		}
		
		//--------------------------------------------------------------------------
		//	
		//  Graphics Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Adds a label
		 * @param	label		Text to display
		 * @param	x			X position of the label
		 * @param	y			Y position of the label
		 * @param	colour		Colour of the text
		 */
		private function addLabel(label:String, x:Number, y:Number, colour:uint, width:Number = 200):void
		{
			var txt:TextField = new TextField();
			txt.defaultTextFormat = new TextFormat("Amiga4Ever", 8, colour);
			txt.selectable = false;
			txt.embedFonts = true;
			txt.text = label;
			txt.width = width;
			txt.height = 15;
			txt.x = x;
			txt.y = y;
			addChild(txt);
		}
	}
}