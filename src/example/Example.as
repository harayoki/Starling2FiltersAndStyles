package example {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	public class Example extends Sprite{

		public function Example() {
			stage.align = StageAlign.TOP_LEFT;
			stage.frameRate = 60;
			stage.color = 0x111111;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			StarlingMain.start(stage);
			
		}

	}
}