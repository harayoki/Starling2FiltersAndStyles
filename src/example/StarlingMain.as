package example {
	import flash.display.Stage;
	import flash.display3D.Context3DProfile;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	import harayoki.starling2.filters.PosterizationFilter;
	import harayoki.starling2.filters.TimeFilterBase;

	import starling.animation.Juggler;

	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFormat;
	import starling.textures.Texture;
	import starling.utils.Align;
	import starling.utils.AssetManager;

	public class StarlingMain extends Sprite{

		private static const BG_COLOR:uint = 0x111111;
		private static const sPoint:Point = new Point();
		private static const UNIT_SIZE:int = 240;
		private static const CONTENT_SIZE:Rectangle = new flash.geom.Rectangle(0, 0, UNIT_SIZE*4, UNIT_SIZE*4);
		private static const IMAGE_SIZE:Rectangle = new flash.geom.Rectangle(0, 0, UNIT_SIZE, UNIT_SIZE);

		public static function start(stage:Stage):void {
			var starling:Starling = new Starling(
				StarlingMain,
				stage,
				CONTENT_SIZE,
				null,
				"auto",
				Context3DProfile.STANDARD_CONSTRAINED
			);
			starling.showStatsAt(Align.LEFT, Align.TOP);
			starling.skipUnchangedFrames = true;
			starling.start();
		}

		private var _assetManager:AssetManager;
		private var _textureNames:Vector.<String> = new <String>[
			 "kota", "lenna", "himawari"
		];
		private var _tid:uint;
		private var _textures:Vector.<Texture> = new <Texture>[];
		private var _quads:Vector.<Quad> = new <Quad>[];
		private var _infos:Vector.<TextField> = new <TextField>[];
		private var _shuffling:Boolean;

		public function StarlingMain() {
			_assetManager = new AssetManager();
			_assetManager.enqueue("atlas.png");
			_assetManager.enqueue("atlas.xml");
			_assetManager.loadQueue(function(ratio:Number):void{
				if(ratio == 1.0) {
					_start();
				}
			});
		}

		private function _getTextureRandomly():Texture {
			return _textures[Math.floor(Math.random()*_textures.length)];
		};

		private function _getNextTexture(current:Texture):Texture {
			var index:int = _textures.indexOf(current);
			if(index < 0) {
				return _getTextureRandomly();
			}
			index = (index + 1) % _textures.length;
			return _textures[index];
		};

		private function _start():void {

			for each(var textureName:String in _textureNames) {
				_textures.push(_assetManager.getTexture(textureName));
			}
			trace(_textures);

			var moveCnt:uint = 0;
			var bg:Quad = Quad.fromTexture(_assetManager.getTexture("white"));
			bg.width = CONTENT_SIZE.width;
			bg.height = CONTENT_SIZE.height;
			bg.color = BG_COLOR;
			addChild(bg);
			bg.addEventListener(TouchEvent.TOUCH, function(ev:TouchEvent):void{
				if(ev.getTouch(bg.parent, TouchPhase.HOVER)) {
					moveCnt++;
					_resetTimer();
//					for each(var tf:TextField in _infos) {
//						tf.visible = false;
//					}
				}
			});

			var mainInfo:TextField = _createInfo(IMAGE_SIZE.width, 0,
				[
					"Harayoki's Filter and Style Classes", "for Starling 2.x",
					"",
					"CC0 1.0 Universal",
					"All codes are licensed under CC0.",
					"http://creativecommons.org/publicdomain/zero/1.0/deed.ja"
				].join("\n")
			);
			var mainQuad:Quad = _createImage(0, 0, "NO EFFECT", function(movePoint:Point):void{
				//mainInfo.visible = true;
			});

			////////// POSTERIZATION //////////

			var pstInfo:TextField = _createInfo(0, IMAGE_SIZE.height, "");
			var pstFilter:PosterizationFilter = new PosterizationFilter(8,8,8,8);
			var pstQuad:Quad = _createImage(
				IMAGE_SIZE.width, IMAGE_SIZE.height, "POSTERIZATION", function(movePoint:Point):void {
					updatePstInfo(movePoint);
			});
			var updatePstInfo:Function = function(movePoint:Point=null):void {
				//pstInfo.visible = true;
				if(movePoint && movePoint.x != 0) {
					var dx:int = movePoint.x > 0 ? 1 : -1;
					var dy:int = movePoint.y > 0 ? 1 : -1;
					switch (moveCnt % 3) {
						case 0:
							pstFilter.redDiv = (pstFilter.redDiv + dx) % 16;
							break;
						case 1:
							pstFilter.greenDiv = (pstFilter.greenDiv + dx) % 16;
							break;
						case 2:
							pstFilter.blueDiv = (pstFilter.blueDiv + dx) % 16;
							break;
					}
				}
				if(movePoint && movePoint.y != 0) {
					switch (moveCnt % 3) {
						case 0:
							pstFilter.blueDiv = (pstFilter.blueDiv + dy) % 16;
							break;
						case 1:
							pstFilter.redDiv = (pstFilter.redDiv + dy) % 16;
							break;
						case 2:
							pstFilter.greenDiv = (pstFilter.greenDiv + dy) % 16;
							break;
					}
				}
				pstInfo.text = [
					"Posterization Filter|Style",
					"",
					"  Red Div :" + (" " + pstFilter.redDiv).slice(-2),
					"Green Div :" + (" " + pstFilter.greenDiv).slice(-2),
					" Blue Div :" + (" " + pstFilter.blueDiv).slice(-2),
					"Alpha Div :" + (" " + pstFilter.alphaDiv).slice(-2)
				].join("\n");
			};
			pstQuad.filter = pstFilter;
			updatePstInfo();

			////////// T //////////

			var timeBaseFilter:TimeFilterBase = new TimeFilterBase();
			Starling.juggler.add(timeBaseFilter);
			var timeBaseInfo:TextField = _createInfo(IMAGE_SIZE.width*3, IMAGE_SIZE.height*0, "aaaa");
			var timerBaseQuad:Quad = _createImage(
				IMAGE_SIZE.width*2, 0, "TIMER BASE TEST", function(movePoint:Point):void {
					updateTimerBaseInfo(movePoint);
				});
			var updateTimerBaseInfo:Function = function(movePoint:Point=null):void {
				if(movePoint) {
				}
			};
			timerBaseQuad.filter = timeBaseFilter;
			updateTimerBaseInfo();

			//////////

			_shuffleImages();

		}

		private function _createInfo(xx:int, yy:int, text:String="", scale:Number=1.0):TextField {
			var font:BitmapFont = TextField.getBitmapFont("mini");
			var border:int = 16;
			var tf:TextField = new TextField(IMAGE_SIZE.width - border*2, IMAGE_SIZE.height- border*2, text);
			tf.format = new TextFormat(font.name, 8*scale, 0xffffff);
			tf.x = xx + border;
			tf.y = yy + border;
			// tf.autoScale = true;
			tf.batchable = true;
			tf.border = false;
			tf.touchable = false;
			//tf.visible = false;
			addChild(tf);
			_infos.push(tf);
			return tf;
		}

		private function _createImage(xx:int, yy:int, title:String, moveHandler:Function=null, hoverHandler:Function=null, picChangeHadler:Function=null):Quad {
			var targetAlpha:Number = 1.0;
			var tfContainer:Sprite;
			var q:Quad = Quad.fromTexture(_getTextureRandomly());
			var tid:uint;
			var font:BitmapFont = TextField.getBitmapFont("mini");
			var hoverCnt:uint = 0;
			q.x = xx + 1;
			q.y = yy + 1;
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
				var touchMove:Touch = ev.getTouch(q, TouchPhase.HOVER);
				var touchBegan:Touch = ev.getTouch(q, TouchPhase.BEGAN);
				if(touchBegan){
					targetAlpha = 0.0;
					fadeInAfter(1000);
					if(hoverHandler != null) {
						hoverHandler.apply(null, [touchBegan.getLocation(q.parent,sPoint), ++hoverCnt])
					}
				} else if(touchEnd){
					q.texture = _getNextTexture(q.texture);
					targetAlpha = 0.0;
					fadeInAfter(1000);
					if(picChangeHadler) {
						picChangeHadler.apply(null, [touchEnd.getLocation(q.parent,sPoint)]);
					}
				} else if(touchMove){
					_resetTimer();
					targetAlpha = 0.0;
					fadeInAfter(1000);
					if(moveHandler != null) {
						moveHandler.apply(null, [touchMove.getMovement(q.parent, sPoint)]);
					}
				}
			});
			function createText(xx:int,yy:int,color:uint):TextField{
				var border:int = 4;
				var tf:TextField = new TextField(IMAGE_SIZE.width - border*2, IMAGE_SIZE.height - border*2, title);
				tf.format = new TextFormat(font.name, 8*5, color);
				tf.x = xx + border;
				tf.y = yy + border;
				tf.batchable = true;
				return tf;
			}
			tfContainer = new Sprite();
			tfContainer.alpha = 0.0;
			tfContainer.x = xx;
			tfContainer.y = yy;
			tfContainer.touchGroup = true;
			tfContainer.touchable = false;
			addChild(tfContainer);

			var bg:Image = new Image(_assetManager.getTexture("slash"));
			bg.width = IMAGE_SIZE.width;
			bg.height = IMAGE_SIZE.height;
			bg.tileGrid = new flash.geom.Rectangle(0, 0, 64, 64);
			bg.color = BG_COLOR;
			tfContainer.addChild(bg);
			tfContainer.addChild(createText(0, 0, 0x000000));
			tfContainer.addChild(createText(2, 2, 0x000000));
			tfContainer.addChild(createText(1, 1, 0xffffff));
			tfContainer.addEventListener(Event.ENTER_FRAME, function(ev:Event):void {
				var da:Number = targetAlpha - tfContainer.alpha;
				if(Math.abs(da) < 0.001) {
					da = 0;
					tfContainer.alpha = targetAlpha;
				}
				if(da < 0) {
					tfContainer.alpha += da * 0.200;
				} else if (da > 0) {
					tfContainer.alpha += da * 0.075;
				}
				tfContainer.visible = tfContainer.alpha >= 0;
			});
			return q;
		}

		private function _shuffleImages():void {
			if(_shuffling) return;
			_shuffling = true;
			function chageAll():void {
				for each (var q:Quad in _quads) {
					q.texture = _getNextTexture(q.texture);
				}
			}
			setTimeout(chageAll, 50);
			setTimeout(chageAll, 100);
			setTimeout(function():void{
				chageAll();
				_shuffling = false;
			}, 200);
			for each (var q:Quad in _quads) {
				q.texture = _getTextureRandomly();
			}
			_resetTimer();
		}

		private function _resetTimer():void {
			if(_tid > 0) {
				clearTimeout(_tid);
				_tid = 0;
			}
			_tid = setTimeout(_shuffleImages, 10.0 * 1000)
		}
	}
}
