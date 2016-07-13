package harayoki.starling2.filters {

	import starling.animation.IAnimatable;
	import starling.filters.FragmentFilter;
	import starling.rendering.FilterEffect;

	public class SlashSadeFilter extends FragmentFilter implements IAnimatable
	{
		public static const LOWER_RIGHT:int = 0;
		public static const LOWER_LEFT:int = 1;

		private var _direction:int = 0;
		private var _strength:int = 1;
		private var _offset:Number = 0.0;
		private var _color:uint = 0;
		private var _alpha:Number = 1.0;

		public var timeScale:Number = 1.0;

		public function SlashSadeFilter(
			direction:int=SlashSadeFilter.LOWER_RIGHT, strength:int=4, color:uint=0x000000, alpha:Number=1.0):void
		{
			_direction = direction == LOWER_RIGHT ? LOWER_RIGHT : LOWER_LEFT;
			_strength = slashShadedEffect.strength = strength;
			_color = color;
			_updateColor();
			_alpha = slashShadedEffect.alphaShade = alpha < 0.0 ? 0.0 : alpha;
		}

		public function advanceTime(time:Number):void {
			offset += 32 * time * timeScale;
		}

		override protected function createEffect():FilterEffect
		{
			return new SlashShadedEffect();
		}

		private function get slashShadedEffect():SlashShadedEffect
		{
			return effect as SlashShadedEffect;
		}

		public function get color():uint { return _color; }
		public function set color(value:uint):void
		{
			if(_color != value) {
				_color = value;
				_updateColor();
				setRequiresRedraw();
			}
		}
		private function _updateColor():void {
			var r:Number = ((_color & 0xff0000) >> 16) / 255;
			var g:Number = ((_color & 0x00ff00) >> 8) / 255 ;
			var b:Number = ((_color & 0x0000ff)) / 255;
			slashShadedEffect.redShade = r;
			slashShadedEffect.greenShade = g;
			slashShadedEffect.blueShade = b;
		}

		public function get alpha():Number { return _alpha; }
		public function set alpha(value:Number):void
		{
			value = value < 0.0 ? 0.0 : value;
			if(_alpha != value) {
				_alpha = value;
				slashShadedEffect.alphaShade = _alpha;
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

		public function get direction():int { return _direction; }
		public function set direction(value:int):void
		{
			if(_direction != value) {
				_direction = value;
				slashShadedEffect.direction = _direction;
				setRequiresRedraw();
			}
		}

		public function get strength():Number { return _strength; }
		public function set strength(value:Number):void
		{
			//５より大きいと表示が荒れる
			if(Math.abs(value) > 5) {
				value = value < 0 ? -5 : 5;
			}
			if(_strength != value) {
				_strength = value;
				slashShadedEffect.strength = _strength;
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
import harayoki.stage3d.agal.registers.AGALRegister;
import harayoki.stage3d.agal.registers.AGALRegisterConstant;
import harayoki.stage3d.agal.registers.AGALRegisterFragmentTemporary;

import starling.rendering.FilterEffect;
import starling.rendering.Program;

internal class SlashShadedEffect extends FilterEffect
{
	private var _color:Vector.<Number>;
	private var _params:Vector.<Number>;
	private var _nums:Vector.<Number>;

	public function SlashShadedEffect()
	{
		_color = new Vector.<Number>(4, true);
		_params = new <Number>[0, 1, 1, 0];
		_params.fixed = true;
		_nums = new <Number>[0, 1, 2, 3];
		_nums.fixed = true;
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
		trace("");
		trace("________ Fragment Program __________");
		trace(fragmentShaderPrinter.printWithLineNum());

		return Program.fromSource(vertexProgram, fragmentProgram);
	}

	override protected function beforeDraw(context:Context3D):void
	{
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _color);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _params );
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, _nums );
		super.beforeDraw(context);
	}

	public function set redShade(value:Number):void {
		_color[0] = value;
	}

	public function set greenShade(value:Number):void {
		_color[1] = value;
	}

	public function set blueShade(value:Number):void {
		_color[2] = value;
	}

	public function set alphaShade(value:Number):void {
		_color[3] = value;
	}

	public function set strength(value:Number):void {
		//// -1 と 1 は効果がないので値を大きくする
		//if (value < 0) {
		//	value--;
		//} else if (value > 0) {
		//	value++
		//}
		_params[1] = value;

	}

	public function set direction(value:int):void {
		_params[2] = value <= 0 ? 0 : 1;
	}

	public function set offset(value:Number):void {
		_params[3] = value;
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

		// tex ft0, v0, fs0 <2d, ****>

		var FILL_COLOR:AGALRegisterConstant  = fc0;

		move(ft6, fc1); // 定数同士の演算エラーになるのをさけるためftに取り出す (お決まりパターン)
		move(ft7, fc2); // 定数同士の演算エラーになるのをさけるためftに取り出す (お決まりパターン)

		// フィルターパラメータ
		var STRENGTH:AGALRegister = ft6.y;
		var STRENGTH_xyzw:AGALRegister = ft6.yyyy;
		var DIRECTION:AGALRegister = ft6.z;
		var OFFSET:AGALRegister = ft6.w;

		// 基本演算用
		var ZERO:AGALRegister = ft7.x;
		var ONE:AGALRegister = ft7.y;
		var TWO:AGALRegister = ft7.z;
		var THREE:AGALRegister = ft7.w;

		// PMA(premultiplied alpha)演算されているのを元の値に戻す  rgb /= a (お決まりパターン)
		divide(ft0.xyz, ft0.xyz, ft0.www);

		// 座標値取得
		move(ft1, v1);

		// オフセット移動 (MATRIXにはいれていない)
		add(ft1.y, ft1.y, OFFSET);

		// 少数部分破棄 (お決まりパターン)
		fractional(ft2, ft1);
		subtract(ft1, ft1, ft2);

		// STRENGTHで割った余りを求める
		divide(ft2, ft1, STRENGTH_xyzw); // ex) 8.0 / 3.0 = 2.6666
		fractional(ft3, ft2); // ex) 2.6666 -> 0.6666
		subtract(ft2, ft2, ft3); // ex) 2.6666 - 0.6666 = 2.0
		multiply(ft2, ft2, STRENGTH_xyzw); // ex) 2.0 * 3.0 = 6.0;
		subtract(ft2, ft1, ft2); // ex) 8.0 - 6.0 = 2.0

		// 描画フラグ
		add(ft2.z, ft2.x, ft2.y); // ex) z = (x % N) + (y % N)
		subtract(ft2.w, STRENGTH, ONE); // ex) str - 1.0
		setIfEqual(ft2.z, ft2.z, ft2.w);

		// 描画フラグ反転処理  (お決まりパターン)
		setIfEqual(ft2.w, ft2.z, ZERO);

		// ONならテクスチャカラーをそのまま使う、OFFならいったん黒になる 透明度は後の計算のため、そのままキープ
		multiply(ft0.xyz, ft0.xyz, ft2.zzz);

		// RGBカラー適用
		move(ft3, FILL_COLOR);
		multiply(ft3.xyzw, ft3.xyzw, ft2.wwww); // 黒くなった部分を指定カラーで塗りつぶす
		multiply(ft3.w, ft3.w, ft0.w); //α 値は元の透明度をいかして掛け合わせる
		multiply(ft0.w, ft0.w, ft2.z); //透明度マスク
		add(ft0, ft0, ft3);

		// PMAをやり直す rgb *= a (お決まりパターン)
		multiply(ft0.xyz, ft0.xyz, ft0.www);

		move(oc, ft0);

	}

}
/*
 (x%N)+(y%N)==N-1; || x==y
 */