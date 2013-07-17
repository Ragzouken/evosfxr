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
	import flash.display.Shape;
	import flash.display.Sprite;
	/**
	 * ...
	 * @author Mark Wonnacott
	 */
	public class Visualisation extends Sprite
	{
		private var _x:int;
		private var _y:int;
		private var _graphic:Shape;
		private var _enabled:Boolean;
		
		/** Enables/disables the graphic */
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void
		{
			if(value) 	alpha = 1.0;
			else		alpha = 0.3;
			
			_enabled = value;
		}
		
		public function Visualisation(x:int, y:int, params:SfxrParams)
		{
			_x = x;
			_y = y;
			_graphic = new Shape();
			
			addChild(_graphic);
			
			draw(params);
		}
		
		public function refresh(params:SfxrParams):void
		{
			removeChild(_graphic);
			_graphic = new Shape();
			addChild(_graphic);
			
			draw(params);
		}
		
		private function draw(params:SfxrParams):void
		{
			var lines:Vector.<IGraphicsData> = new Vector.<IGraphicsData>();
			lines.push(new GraphicsStroke(1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 3, new GraphicsSolidFill(0x000000)));
			
			var operations:Vector.<int> = new Vector.<int>();
			var coordinates:Vector.<Number> = new Vector.<Number>;
			
			var data:Vector.<Number> = params.data();
			
			var px:Number = _x, py:Number = _y, pa:Number = 0, nx:Number, ny:Number, na:Number;
			var d:Number = 60/data.length, da:Number = Math.PI / 2;
			var value:Number;
			
			coordinates.push(int(px));
			coordinates.push(int(py));
			operations.push(GraphicsPathCommand.MOVE_TO);
			for (var i:int = 0; i < 12; ++i) {
				value = data[i];
				
				na = pa + value * da;
				nx = px + d * Math.cos(na);
				ny = py + d * Math.sin(na);
				
				coordinates.push(int(nx));
				coordinates.push(int(ny));
				operations.push(GraphicsPathCommand.LINE_TO);
				
				px = nx; py = ny; pa = na;
			}
			
			px = _x; py = _y; pa = Math.PI + da * data[11];
			
			coordinates.push(int(px));
			coordinates.push(int(py));
			operations.push(GraphicsPathCommand.MOVE_TO);
			for (var i:int = 12; i < data.length; ++i) {
				value = data[i];
				
				na = pa + value * -da;
				nx = px + d * Math.cos(na);
				ny = py + d * Math.sin(na);
				
				coordinates.push(int(nx));
				coordinates.push(int(ny));
				operations.push(GraphicsPathCommand.LINE_TO);
				
				px = nx; py = ny; pa = na;
			}
			
			lines.push(new GraphicsPath(operations, coordinates));
			_graphic.graphics.drawGraphicsData(lines);
		}
	}
}