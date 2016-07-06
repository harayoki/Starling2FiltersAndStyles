package example {
	import flash.desktop.NativeApplication;
	import flash.display.BitmapData;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.NativeWindow;
	import flash.display.PNGEncoderOptions;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;

	import starling.core.Starling;

	public class Example extends Sprite{

		public function Example() {
			stage.align = StageAlign.TOP_LEFT;
			stage.frameRate = 60;
			stage.color = 0x111111;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			ExampleMain.start(stage);

			var iid:uint = setInterval(function():void {
				if(Starling.current) {
					clearInterval(iid);
					_initMenu();
				}
			},500);

		}

		private function _initMenu():void {
			if(NativeWindow.isSupported) {

				var starling:Starling = Starling.current;
				var root:NativeMenu = new NativeMenu();
				NativeApplication.nativeApplication.menu = root;
				var subMenu1:NativeMenu = new NativeMenu();
				root.addSubmenu(subMenu1, "menu");
				var item:NativeMenuItem;

				var bmd:BitmapData;
				item = new NativeMenuItem("Capture Screen");
				item.addEventListener(Event.SELECT, function(ev:Event):void{
					var viewPort:Rectangle = starling.viewPort;
					bmd = new BitmapData(viewPort.width, viewPort.height, false, stage.color);
					starling.stage.drawToBitmapData(bmd);
					_saveImage(bmd);
				});
				subMenu1.addItem(item);
			}
		}

		private function _saveImage(bmd:BitmapData):void
		{
			var date:Date = new Date();
			var filename:String = [
					"DemoCapture", date.fullYear, date.month + 1, date.date, date.hours, date.minutes, date.seconds
				].join("_") + ".png";
			var bytes:ByteArray = new ByteArray();
			var options:PNGEncoderOptions = new PNGEncoderOptions();
			bmd.encode(bmd.rect, options, bytes);
			var fr:FileReference = new FileReference();
			fr.save(bytes, filename);
		}
	}
}