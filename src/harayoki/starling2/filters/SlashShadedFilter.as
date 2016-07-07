package harayoki.starling2.filters {

	import starling.filters.FragmentFilter;
	import starling.rendering.FilterEffect;

	public class SlashShadedFilter extends FragmentFilter
	{
		public function SlashShadedFilter(
			redShade:Number=0.0, greenShade:Number=0.0, blueShade:Number=0.0, alphaShade:Number=1.0):void
		{
			slashShadedEffect.redShade = redShade;
			slashShadedEffect.greenShade = greenShade;
			slashShadedEffect.blueShade = blueShade;
			slashShadedEffect.alphaShade = alphaShade;
		}

		override protected function createEffect():FilterEffect
		{
			return new SlashShadedEffect();
		}

		private function get slashShadedEffect():SlashShadedEffect
		{
			return effect as SlashShadedEffect;
		}

		public function get redShade():Number { return slashShadedEffect.redShade; }
		public function set redShade(value:Number):void
		{
			slashShadedEffect.redShade = value < 0.0 ? 0.0 : value;
			setRequiresRedraw();
		}

		public function get greenShade():Number { return slashShadedEffect.greenShade; }
		public function set greenShade(value:Number):void
		{
			slashShadedEffect.greenShade = value < 0.0 ? 0.0 : value;
			setRequiresRedraw();
		}

		public function get blueDiv():Number { return slashShadedEffect.blueShade; }
		public function set blueDiv(value:Number):void
		{
			slashShadedEffect.blueShade = value < 0.0 ? 0.0 : value;
			setRequiresRedraw();
		}

		public function get alphaDiv():Number { return slashShadedEffect.alphaShade; }
		public function set alphaDiv(value:Number):void
		{
			slashShadedEffect.alphaShade = value < 0.0 ? 0.0 : value;
			setRequiresRedraw();
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
		_mat.appendRotation(45, Vector3D.Z_AXIS);
		_mat.appendScale(0.5, 0.5, 1.0);
		_mat.appendTranslation(0, 100, 0);
		_vars = new <Number>[0, 1, 2, 0.05];
		_vars.fixed = true;
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

	public function get redShade():Number { return _color[0]; }
	public function set redShade(value:Number):void { _color[0] = value; }

	public function get greenShade():Number { return _color[1]; }
	public function set greenShade(value:Number):void { _color[1] = value; }

	public function get blueShade():Number { return _color[2]; }
	public function set blueShade(value:Number):void { _color[2] = value; }

	public function get alphaShade():Number { return _color[3]; }
	public function set alphaShade(value:Number):void { _color[3] = value; }

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

		var PARAMS:AGALRegisterConstant = fc1;
		var PARAM_0:AGALRegisterConstant = fc1.x;
		var PARAM_1:AGALRegisterConstant = fc1.y;
		var PARAM_2:AGALRegisterConstant = fc1.z;
		var C11:AGALRegisterConstant = fc1.yy;
		var PARAM_1111:AGALRegisterConstant = fc1.yyyy;
		var C22:AGALRegisterConstant = fc1.zz;
		var PARAM_2222:AGALRegisterConstant = fc1.zzzz;
		var PARAM_P:AGALRegisterConstant = fc1.w;

		var MATRIX:AGALRegisterConstant = fc2;

		// tex ft0, v0, fs0 <2d, ****>

		// PMA(premultiplied alpha)演算されているのを元の値に戻す  rgb /= a
		divide(ft0.xyz, ft0.xyz, ft0.www);

		// 少数部分破棄
		move(ft1, v1);
		multiplyMatrix4x4(ft1, ft1, MATRIX);
		fractional(ft2, ft1);
		subtract(ft1, ft1, ft2);

		// 偶数判定
		divide(ft2, ft1, PARAM_2);
		fractional(ft2, ft2);
		setIfEqual(ft2.z, ft2.y, PARAM_0);

		multiply(ft0.xyz, ft0.xyz, ft2.zzz);

		setIfNotEqual(ft2.z, ft2.y, PARAM_0);
		move(ft3, fc0);
		multiply(ft3, ft3, ft2.zzzz);
		multiply(ft3.w, ft3.w, ft0.w);
		add(ft0, ft0, ft3);

		// PMAをやり直す rgb *= a
		multiply(ft0, ft0.xyz, ft0.www);

		move(oc, ft0);

	}

}

/*

 ////////// x % 4 と y % 4 を作る //////////

 // ft1 = Math.floor(v1)
 fractional(ft1, v1); // ex) 15.4 -> 0.4
 subtract(ft1, v1, ft1); // ex) ft1 = 15.4 - 0.4 = 15

 // ft2 = ft1 / 4
 divide(ft2.xyzw, ft1.xyzw, fc1.wwww);  // ex) ft2 = 15/4 = 3.75

 // ft2 = Math.floor(ft2);
 fractional(ft3, ft2); // ex) ft3 = 0.75
 subtract(ft2, ft2, ft3); // ex) ft2 = 3

 // ft2*=4
 multiply(ft2.xyzw, ft2.xyzw, fc1.wwww); // ex) ft2 = 12

 // ft1 = ft1 - ft2
 subtract(ft1, ft1, ft2); // ex) ft1 = 3

 ////////// (x%4)+(y%4) == 3 なら処理を変える //////////

 // z = x + y
 add(ft1.z, ft1.x, ft1.y);

 // ft3.x =  (z == 3) ? 1 : 0
 setIfNotEqual(ft3.x, ft1.z, fc1.w);

 // ft3.y =  !ft3.x
 setIfNotEqual(ft3.y, ft3.x, fc1.y)

 multiply(ft0.xyzw, ft0.xyzw, ft3.xxxx);

 move(ft2, fc0);
 multiply(ft2.xyzw, ft2.xyzw, ft3.yyyy);
 add(oc, ft0, ft2);
 */