package example {
	import flash.display.Stage;
	import flash.display3D.Context3DProfile;
	import flash.geom.Point;
	import flash.geom.Rectangle;

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
			var topleft:Quad = _createQuad(10, 10, "POSTERIZATION\nFILTER", function(movePoint:Point){
				if(movePoint.x > 0) {
					posterizationFilter.redDiv = 1 + (posterizationFilter.redDiv % 10);
					posterizationFilter.blueDiv = -1 + (posterizationFilter.blueDiv % 10);
				} else if(movePoint.x < 0) {
					posterizationFilter.redDiv = -1 + (posterizationFilter.redDiv % 10);
					posterizationFilter.blueDiv = 1 + (posterizationFilter.blueDiv % 10);
				}
				if(movePoint.y > 0) {
					posterizationFilter.greenDiv = 1 + (posterizationFilter.greenDiv % 10);
				} else if(movePoint.y < 0) {
					posterizationFilter.greenDiv = -1 + (posterizationFilter.greenDiv % 10);
				}
			});
			topleft.filter = posterizationFilter;

			// var bottomLeft:Quad = _createQuad(10, 480 + 30);

		}

		private function _createQuad(xx:int, yy:int, title:String=null, moveHandler:Function=null):Quad {
			var index:uint = ~~(Math.random()*_images.length);
			var wait:int = 60 * 2.0;
			var tfContainer:Sprite;
			var q:Quad = Quad.fromTexture(_getTexture(index));
			var font:BitmapFont = TextField.getBitmapFont("mini");
			q.x = xx;
			q.y = yy;
			addChild(q);
			_quads.push(q);
			q.addEventListener(TouchEvent.TOUCH, function(ev:TouchEvent):void{
				if(ev.getTouch(q, TouchPhase.ENDED)){
					index++;
					q.texture = _getTexture(index);
					if(tfContainer) {
						wait = 60 * 5.0;
						tfContainer.alpha = 1.0;
					}
				} else {
					var touchMove:Touch = ev.getTouch(q, TouchPhase.HOVER);
					if(moveHandler != null && touchMove) {
						moveHandler.apply(null, [touchMove.getMovement(q.parent, sPoint)]);
					}
				}
			});
			if(title) {
				tfContainer = new Sprite();
				tfContainer.alpha = 1.0;
				tfContainer.x = xx;
				tfContainer.y = yy;
				tfContainer.touchGroup = true;
				tfContainer.touchable = false;
				addChild(tfContainer);
				var tf1:TextField = new TextField(240, 240, title);
				tf1.format = new TextFormat(font.name, 48, 0x111111);
				tfContainer.addChild(tf1);
				var tf2:TextField = new TextField(240, 240, title);
				tf2.format = new TextFormat(font.name, 48, 0xffffff);
				tfContainer.addChild(tf2);
				tf2.scale = 0.98;
				tf2.x = 2; tf2.y = 2;
				tf1.addEventListener(Event.ENTER_FRAME, function(ev:Event):void {
					if(wait == 0) {
						if(tfContainer.alpha > 0) {
							tfContainer.alpha -= 0.02;
						}
					} else {
						wait--;
					}
				});
			}
			return q;
		}
	}
}
