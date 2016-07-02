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

import harayoki.stage3d.agal.AGAL1CodePrinterForBaselineExtendedProfile;

import starling.rendering.FilterEffect;
import starling.rendering.Program;

internal class SlashShadedEffect extends FilterEffect
{
	private var _color:Vector.<Number>;
	private var _vars:Vector.<Number>;

	public function SlashShadedEffect()
	{
		_color = new Vector.<Number>(4, true);
		_vars = new <Number>[1, 2, 3, 4];
	}

	override protected function createProgram():Program
	{
		var vertexShaderPrinter:AGAL1CodePrinterForBaselineExtendedProfile = new VertexAGALCodePrinter();
		var vertexProgram:String = vertexShaderPrinter.print();
		var fragmentShaderPrinter:AGAL1CodePrinterForBaselineExtendedProfile = new FragmentAGALCodePrinter();
		var fragmentProgram:String = tex("ft0", "v0", 0, texture) + // tex ft0, v0, fs0 <2d, linear/rgba>
			fragmentShaderPrinter.print();
		trace(vertexShaderPrinter.printWithLineNum());
		trace(fragmentShaderPrinter.printWithLineNum());
		return Program.fromSource(vertexProgram, fragmentProgram);
	}

	override protected function beforeDraw(context:Context3D):void
	{
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _color);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _vars );
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
	}
}

internal class FragmentAGALCodePrinter extends AGAL1CodePrinterForBaselineExtendedProfile {

	public override function setupCode():void {

//		////////// x % 4 と y % 4 を作る //////////
//
//		// ft1 = ft0 / 4
//		divide(ft1.xyzw, ft0.xyzw, fc1.wwww);
//
//		// ft1の小数点以下を破棄
//		fractional(ft2, ft1);
//		subtract(ft1, ft1, ft2);
//
//		// ft1*=4
//		multiply(ft1.xyz, ft1.xyz, fc1.www);
//
//		// ft1 = ft0 - ft1
//		subtract(ft1, ft0, ft1);
//
//		////////// (x%4)+(y%4) == 3 なら処理を変える //////////
//
//		// z = x + y
//		add(ft1.z, ft1.x, ft1.y);
//
//		// z =  z != 3 ? 1 : 0
//		setIfEqual(ft1.z, ft1.z, fc1.z)
//
//		multiply(ft1.xyzw, va1.xyzw, ft1.zzzz);

		// ocに出力
		move(oc, ft0);
	}

	/* output
	 */

}

// ここでw要素も計算しないと次のfractionalでvt1が初期化されてないと怒られる要素全部の初期化が必要な模様
// Temporary register component read without being written to for source operand 1 at token 4 of vertex program.

// ここで引数2のvt1.xyzをv1.xyzと書き間違えたらvertexシェーダーではvレジスタは読み込めないと怒られた
// Varying registers can only be read in fragment programs for source operand 1 at token 6 of vertex program.

// ここでva1に書き込もうとして怒られた
// Attribute registers can not be written to for destination operand at token 10 of vertex program.
