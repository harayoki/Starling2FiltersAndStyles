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
			timePassed += time;
			timeEffect.timePassed = timePassed * 2;
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
	protected var _agalVersion:uint = 1;
	protected var _params0:Vector.<Number>;

	public function TimeEffect()
	{
		_params0 = new Vector.<Number>(4, true);
		_params0[1] = 1;
		_params0[2] = 5;
		_params0[3] = 0.5;
	}

	override protected function createProgram():Program
	{
		var vertexShader:String = _createTimeEffectVertexShader();
		var fragmentShader:String = _createTimeEffectFragmentShader();
		return Program.fromSource(vertexShader, fragmentShader, _agalVersion);
	}

	protected function _createTimeEffectVertexShader():String {
		var printer:VertexShaderPrinter = new VertexShaderPrinter();
		return printer.print();
	}

	protected function _createTimeEffectFragmentShader():String {
		return [tex("ft0", "v0", 0, texture), "mov oc, ft0"].join("\n");
	}

	override protected function beforeDraw(context:Context3D):void
	{
		context.setProgramConstantsFromVector(
			Context3DProgramType.VERTEX,
			127,
			_params0
		);
		super.beforeDraw(context);
	}

	public function get timePassed():Number { return _params0[0]; }
	public function set timePassed(value:Number):void { _params0[0] = value;}

}

internal class VertexShaderPrinter extends AGAL1CodePrinterForBaselineExtendedProfile {

	public override function setupCode():void {

		//回転行列を座標に掛け合わせる
		multiplyMatrix4x4(vt1, va0, vc0);

		move(vt0, vc127);
		add(vt0.x, vt0.x, va0.y);
		sine(vt0.x, vt0.x); // sine(time)
		add(vt0.x, vt0.x, vc127.w); // + 0.5
		multiply(vt1.x, vt1.x, vt0.x);
		move(op, vt1);

		//カラーはそのまま受けわたす
		move(v0, va1);

	}
}