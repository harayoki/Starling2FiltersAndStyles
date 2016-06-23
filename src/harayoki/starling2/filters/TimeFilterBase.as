package harayoki.starling2.filters {

	import starling.animation.IAnimatable;
	import starling.filters.FragmentFilter;
	import starling.rendering.FilterEffect;

	public class TimeFilterBase extends FragmentFilter implements IAnimatable
	{
		protected var timePassed:Number = 0;
		public function TimeFilterBase():void
		{
		}

		override protected function createEffect():FilterEffect
		{
			return new TimeEffect();
		}

		public function advanceTime(time:Number):void {
			timeEffect.timePassed += time;
			setRequiresRedraw();
		}

		private function get timeEffect():TimeEffect
		{
			return effect as TimeEffect;
		}

	}
}

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

import harayoki.stage3d.agal.AGAL1CodePrinterForBaselineExtendedProfile;

import starling.rendering.FilterEffect;
import starling.rendering.Program;

class TimeEffect extends FilterEffect
{
	private var _divs0:Vector.<Number>;

	public function TimeEffect()
	{
		_divs0 = new Vector.<Number>(4, true);
	}

	override protected function createProgram():Program
	{
		var vertexShader:String = STD_VERTEX_SHADER;

		// STD_VERTEX_SHADER
		//回転行列を座標に掛け合わせる
		//"m44 op, va0, vc0 \n" +
		//カラーはそのまま受けわたす
		//"mov v0, va1";

		var printer:AGAL1CodePrinterForBaselineExtendedProfile = new MyAGALCodePrinter();
		printer.prependCodeDirectly(tex("ft0", "v0", 0, texture)); // tex ft0, v0, fs0 <2d, linear/rgba>
		var fragmentShader:String = printer.print();

		return Program.fromSource(vertexShader, fragmentShader);
	}

	override protected function beforeDraw(context:Context3D):void
	{
		context.setProgramConstantsFromVector(
			Context3DProgramType.FRAGMENT,
			0,
			_divs0
		);
		super.beforeDraw(context);
	}

	public function get timePassed():Number { return _divs0[0]; }
	public function set timePassed(value:Number):void { _divs0[0] = value; }

}

internal class MyAGALCodePrinter extends AGAL1CodePrinterForBaselineExtendedProfile {

	public override function setupCode():void {

		move(oc, ft0);
		return;

		// PMA(premultiplied alpha)演算されているのを元の値に戻す  rgb /= a
		divide(ft0.xyz, ft0.xyz, ft0.www);

		// 各チャンネルにRGBA定数値(fc0)を掛け合わせる
		multiply(ft0, ft0, fc0);

		// ft0の小数点以下を破棄 ft1 = ft0 - float(ft0)、ft0 -= ft1
		fractional(ft1, ft0);
		subtract(ft0, ft0, ft1);

		// ft0の各要素から1を引いた値をft1に作る
		move(ft1, fc0);
		saturate(ft1, ft1); // 全要素が2以上であることが保証されているので(1,1,1,1)になる
		subtract(ft1, fc0, ft1);

		// ft0の値より1小さい値で割る
		divide(ft0, ft0, ft1);

		// 1.0を超える部分ができるので正規化
		saturate(ft0, ft0);

		// PMAをやり直す rgb *= a
		multiply(ft0.xyz, ft0.xyz, ft0.www);

		// ocに出力
		move(oc, ft0);

	}

	/* output
	 div ft0.xyz, ft0.xyz, ft0.www
	 mul ft0, ft0, fc0
	 frc ft1, ft0
	 sub ft0, ft0, ft1
	 mov ft1, fc0
	 sat ft1, ft1
	 sub ft1, fc0, ft1
	 div ft0, ft0, ft1
	 sat ft0, ft0
	 mul ft0.xyz, ft0.xyz, ft0.www
	 mov oc, ft0
	 */

}