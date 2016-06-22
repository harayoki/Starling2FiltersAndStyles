package example {
	import flash.display.Stage;
	import flash.display3D.Context3DProfile;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	import harayoki.starling2.filters.PosterizationFilter;

	import starling.core.Starling;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.BitmapFont;
	import starling.text.MiniBitmapFont;
	import starling.text.TextField;
	import starling.text.TextFormat;
	import starling.textures.Texture;
	import starling.utils.Align;
	import starling.utils.AssetManager;

	public class StarlingMain extends Sprite{

		private static const sPoint:Point = new Point();
		private static const CONTENT_SIZE:Rectangle = new flash.geom.Rectangle(0, 0, 760, 760);

		public static function start(stage:Stage):void {
			var starling:Starling = new Starling(
				StarlingMain,
				stage,
				CONTENT_SIZE,
				null,
				"auto",
				Context3DProfile.STANDARD_CONSTRAINED
			);
			starling.showStatsAt(Align.RIGHT, Align.BOTTOM);
			starling.skipUnchangedFrames = true;
			starling.start();
		}

		private var _assetManager:AssetManager;
		private var _images:Array = [
			 "kota.png"
			,"lenna.png"
		];
		private var _quads:Vector.<Quad> = new <Quad>[];

		public function StarlingMain() {
			_assetManager = new AssetManager();
			_assetManager.enqueue(_images);
			_assetManager.loadQueue(function(ratio:Number):void{
				if(ratio == 1.0) {
					_start();
				}
			});
		}

		private function _getTexture(index:uint):Texture {
			return _assetManager.getTexture(_images[index % _images.length].split(".")[0]);
		};

		private function _start():void {

			var center:Quad = _createQuad(240+20, 240+20, "NORMAL");

			var posterizationFilter:PosterizationFilter = new PosterizationFilter(8,8,8,8);
			var touchCnt:uint = 0;
			var topleft:Quad = _createQuad(10, 10, "POSTERIZATION\nFILTER", function(touchPoint:Point, cnt:uint):void{
				touchCnt = cnt;
			},function(movePoint:Point){
				var cnt:uint = touchCnt % 3;
				if(movePoint.x != 0) {
					var dx:int = movePoint.x > 0 ? 1 : -1;
					var dy:int = movePoint.y > 0 ? 1 : -1;
					switch (cnt) {
						case 0:
							posterizationFilter.redDiv = (posterizationFilter.redDiv + dx) % 12;
							break;
						case 1:
							posterizationFilter.greenDiv = (posterizationFilter.greenDiv + dx) % 12;
							break;
						case 2:
							posterizationFilter.blueDiv = (posterizationFilter.blueDiv + dx) % 12;
							break;
					}
				}
				if(movePoint.y != 0) {
					switch (cnt) {
						case 0:
							posterizationFilter.blueDiv = (posterizationFilter.blueDiv + dy) % 12;
							break;
						case 1:
							posterizationFilter.redDiv = (posterizationFilter.redDiv + dy) % 12;
							break;
						case 2:
							posterizationFilter.greenDiv = (posterizationFilter.greenDiv + dy) % 12;
							break;
					}
				}
			});
			topleft.filter = posterizationFilter;

			// var bottomLeft:Quad = _createQuad(10, 480 + 30);

		}

		private function _createQuad(xx:int, yy:int, title:String=null, picChangeHadler:Function=null, moveHandler:Function=null):Quad {
			var index:uint = ~~(Math.random()*_images.length);
			var targetAlpha:Number = 1.0;
			var tfContainer:Sprite;
			var q:Quad = Quad.fromTexture(_getTexture(index));
			var tid:uint;
			var font:BitmapFont = TextField.getBitmapFont("mini");
			var touchCnt:uint = 0;
			q.x = xx;
			q.y = yy;
			addChild(q);
			_quads.push(q);
			function fadeInAfter(delay:uint):void {
				clearTimeout(tid);
				tid = setTimeout(function():void{
					targetAlpha = 1.0;
				}, delay);
			}
			q.addEventListener(TouchEvent.TOUCH, function(ev:TouchEvent):void{
				var touchEnd:Touch = ev.getTouch(q, TouchPhase.ENDED);
				if(touchEnd){
					index++;
					q.texture = _getTexture(index);
					targetAlpha = 0.0;
					fadeInAfter(1500);
					if(picChangeHadler) {
						picChangeHadler.apply(null, [touchEnd.getLocation(q.parent,sPoint), ++touchCnt]);
					}
				} else {
					var touchMove:Touch = ev.getTouch(q, TouchPhase.HOVER);
					targetAlpha = 0.0;
					fadeInAfter(1500);
					if(moveHandler != null && touchMove) {
						moveHandler.apply(null, [touchMove.getMovement(q.parent, sPoint)]);
					}
				}
			});
			if(title) {
				tfContainer = new Sprite();
				tfContainer.alpha = 0.0;
				tfContainer.x = xx;
				tfContainer.y = yy;
				tfContainer.touchGroup = true;
				tfContainer.touchable = false;
				addChild(tfContainer);
				var tf1:TextField = new TextField(240, 240, title);
				tf1.format = new TextFormat(font.name, 48, 0x111111);
				tfContainer.addChild(tf1);
				var tf2:TextField = new TextField(240, 240, title);
				tf2.format = new TextFormat(font.name, 48, 0x111111);
				tfContainer.addChild(tf2);
				tf2.x = 2; tf2.y = 2;
				var tf3:TextField = new TextField(240, 240, title);
				tf3.format = new TextFormat(font.name, 48, 0xffffff);
				tfContainer.addChild(tf3);
				tf3.x = 1; tf3.y = 1;
				tfContainer.addEventListener(Event.ENTER_FRAME, function(ev:Event):void {
					var da:Number = targetAlpha - tfContainer.alpha;
					if(da < 0) {
						tfContainer.alpha += da * 0.10;
					} else {
						tfContainer.alpha += da * 0.05;
					}
				});
			}
			return q;
		}
	}
}
