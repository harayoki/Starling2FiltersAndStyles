package harayoki.starling2.filters {

	import starling.animation.IAnimatable;
	import starling.filters.FragmentFilter;
	import starling.rendering.FilterEffect;

	public class ScanLineFilter extends FragmentFilter implements IAnimatable
	{
		private var _scale:Number = 1.0;
		private var _degree:Number = 0.0;
		private var _offset:Number = 0.0;
		private var _redShade:Number = 0.0;
		private var _greenShade:Number = 0.0;
		private var _blueShade:Number = 0.0;
		private var _alphaShade:Number = 1.0;

		public var timeScale:Number = 1.0;

		public function ScanLineFilter(
			scale:Number=2, degree:Number=0,
			redShade:Number=0.0, greenShade:Number=0.0, blueShade:Number=0.0, alphaShade:Number=1.0):void
		{
			_scale = scale;
			_degree = degree;
			slashShadedEffect.redShade = _redShade = redShade;
			slashShadedEffect.greenShade = _greenShade = greenShade;
			slashShadedEffect.blueShade = _blueShade = blueShade;
			slashShadedEffect.alphaShade = _alphaShade = alphaShade;
			slashShadedEffect.updateMatrix(_degree, _scale);
		}

		public function advanceTime(time:Number):void {
			offset += time * 0.05 * timeScale;
		}

		override protected function createEffect():FilterEffect
		{
			return new SlashShadedEffect();
		}

		private function get slashShadedEffect():SlashShadedEffect
		{
			return effect as SlashShadedEffect;
		}

		public function get redShade():Number { return _redShade; }
		public function set redShade(value:Number):void
		{
			value = value < 0.0 ? 0.0 : value;
			if(_redShade != value) {
				_redShade = value;
				slashShadedEffect.redShade = _redShade;
				setRequiresRedraw();
			}
		}

		public function get greenShade():Number { return _greenShade; }
		public function set greenShade(value:Number):void
		{
			value = value < 0.0 ? 0.0 : value;
			if(_greenShade != value) {
				_greenShade = value;
				slashShadedEffect.greenShade = _greenShade;
				setRequiresRedraw();
			}
		}

		public function get blueShade():Number { return _blueShade; }
		public function set blueShade(value:Number):void
		{
			value = value < 0.0 ? 0.0 : value;
			if(_blueShade != value) {
				_blueShade = value;
				slashShadedEffect.blueShade = _blueShade;
				setRequiresRedraw();
			}
		}

		public function get alphaShade():Number { return _alphaShade; }
		public function set alphaShade(value:Number):void
		{
			value = value < 0.0 ? 0.0 : value;
			if(_alphaShade != value) {
				_alphaShade = value;
				slashShadedEffect.alphaShade = _alphaShade;
				setRequiresRedraw();
			}
		}

		public function get scale():Number { return _scale; }
		public function set scale(value:Number):void
		{
			value = value < 1.0 ? 1.0 : value;
			if(_scale != value) {
				_scale = value;
				slashShadedEffect.updateMatrix(_degree, _scale)
				setRequiresRedraw();
			}
		}

		public function get degree():Number { return _degree; }
		public function set degree(value:Number):void
		{
			value = value % 360;
			if(_degree != value) {
				_degree = value;
				slashShadedEffect.updateMatrix(_degree, _scale)
				setRequiresRedraw();
			}
		}

		public function get offset():Number { return _offset; }
		public function set offset(value:Number):void
		{
			if(_offset != value) {
				_offset = value;
				slashShadedEffect.offset = _offset;
				setRequiresRedraw();
			}
		}

	}
}

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import harayoki.stage3d.agal.AGAL1CodePrinterForBaselineExtendedProfile;
import harayoki.stage3d.agal.registers.AGALRegisterConstant;

import starling.rendering.FilterEffect;
import starling.rendering.Program;

internal class SlashShadedEffect extends FilterEffect
{
	private var _color:Vector.<Number>;
	private var _vars:Vector.<Number>;
	private var _mat:Matrix3D;

	public function SlashShadedEffect()
	{
		_color = new Vector.<Number>(4, true);
		_mat = new Matrix3D();
		_vars = new <Number>[0, 1, 2, 0];
		_vars.fixed = true;
		updateMatrix(0, 1);
	}

	override protected function createProgram():Program
	{
		var vertexShaderPrinter:AGAL1CodePrinterForBaselineExtendedProfile = new VertexAGALCodePrinter();
		var vertexProgram:String = vertexShaderPrinter.print();

		var fragmentShaderPrinter:AGAL1CodePrinterForBaselineExtendedProfile = new FragmentAGALCodePrinter();
		fragmentShaderPrinter.prependCodeDirectly(tex("ft0", "v0", 0, texture)); // tex ft0, v0, fs0 <2d, linear/rgba>
		var fragmentProgram:String = fragmentShaderPrinter.print();

		//tex == RenderUtil.createAGALTexOperation

		trace("__________ Vertex Program __________");
		trace(vertexShaderPrinter.printWithLineNum());
		trace("________ Fragment Program __________");
		trace(fragmentShaderPrinter.printWithLineNum());

		return Program.fromSource(vertexProgram, fragmentProgram);
	}

	override protected function beforeDraw(context:Context3D):void
	{
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _color);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _vars );
		context.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, 2, _mat);
		super.beforeDraw(context);
	}

	public function set redShade(value:Number):void { _color[0] = value; }

	public function set greenShade(value:Number):void { _color[1] = value; }

	public function set blueShade(value:Number):void { _color[2] = value; }

	public function set alphaShade(value:Number):void { _color[3] = value; }

	public function set offset(value:Number):void { _vars[3] = value; }

	public function updateMatrix(degree:Number, scale:Number):void {
		_mat.identity();
		_mat.appendRotation(degree, Vector3D.Z_AXIS);
		_mat.appendScale(1/ scale, 1/ scale, 1.0);
	}

}

internal class VertexAGALCodePrinter extends AGAL1CodePrinterForBaselineExtendedProfile {
	public override function setupCode():void {
		multiplyMatrix4x4(vt0, va0, vc0);
		move(op, vt0);
		move(v0, va1);
		move(v1, va0);
	}
}

internal class FragmentAGALCodePrinter extends AGAL1CodePrinterForBaselineExtendedProfile {

	public override function setupCode():void {

		var ZERO:AGALRegisterConstant   = fc1.x;
		var ONE:AGALRegisterConstant   = fc1.y;
		var TWO:AGALRegisterConstant   = fc1.zzzz;
		var OFFSET:AGALRegisterConstant = fc1.w;
		var MATRIX:AGALRegisterConstant = fc2;

		// tex ft0, v0, fs0 <2d, ****>

		// PMA(premultiplied alpha)演算されているのを元の値に戻す  rgb /= a
		divide(ft0.xyz, ft0.xyz, ft0.www);

		// 座標値取得
		move(ft1, v1);

		// オフセット移動
		add(ft1.y, ft1.y, OFFSET);

		// 少数部分破棄
		multiplyMatrix3x3(ft1.xyz, ft1.xyz, MATRIX);
		fractional(ft2, ft1);
		subtract(ft1, ft1, ft2);

		// 偶数判定
		divide(ft2, ft1, TWO);
		fractional(ft2, ft2);
		setIfEqual(ft2.z, ft2.y, ZERO);

		// 偶数ならテクスチャカラーをそのまま使う、奇数なら黒になる
		multiply(ft0.xyzw, ft0.xyzw, ft2.zzzz);

		// 奇数なら指定カラーで塗りつぶす
		setIfNotEqual(ft2.z, ft2.z, ONE);
		move(ft3, fc0);
		multiply(ft3, ft3, ft2.zzzz);
		multiply(ft3.w, ft3.w, ft0.w);
		add(ft0, ft0, ft3);

		// PMAをやり直す rgb *= a
		multiply(ft0.xyz, ft0.xyz, ft0.www);

		move(oc, ft0);

	}

}
