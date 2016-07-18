package harayoki.starling2.filters {

	import starling.animation.IAnimatable;
	import starling.filters.FragmentFilter;
	import starling.rendering.FilterEffect;

	public class SlashShadedFilter extends FragmentFilter implements IAnimatable
	{
		public static const TYPE_SLASH:int = 0;
		public static const TYPE_BACK_SLASH:int = 1;

		private var _type:int = 0;
		private var _distance:int = 1;
		private var _offset:Number = 0.0;
		private var _color:uint = 0;
		private var _alpha:Number = 1.0;

		public var timeScale:Number = 1.0;

		public function SlashShadedFilter(
			distance:int=4, color:uint=0x000000, alpha:Number=1.0, type:int=SlashShadedFilter.TYPE_SLASH):void
		{
			_type = slashShadedEffect.type = (type == TYPE_SLASH) ? TYPE_SLASH : TYPE_BACK_SLASH;
			_distance = slashShadedEffect.distance = distance;
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

		public function get type():int { return _type; }
		public function set type(value:int):void
		{
			if(_type != value) {
				_type = value;
				slashShadedEffect.type = _type;
				setRequiresRedraw();
			}
		}

		public function get distance():Number { return _distance; }
		public function set distance(value:Number):void
		{
			if(_distance != value) {
				_distance = value;
				slashShadedEffect.distance = _distance;
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
import harayoki.stage3d.agal.i.IAGALRegister;
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

	public function set distance(value:Number):void {
		// -1 と 1 は効果がないので値を大きくする
		value ++;
		if (value <= 1) {
			value = 0;
		}
		_params[1] = value;

	}

	public function set type(value:int):void {
		_params[2] = (value == 0) ? 0 : 1;
		offset = _params[3];
	}

	public function set offset(value:Number):void {
		_params[3] = _params[2] == 0 ? value : -value;
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
		var PARAMS:AGALRegister = ft6;
		var DISTANCE:AGALRegister = PARAMS.y;
		var DISTANCE_xyzw:AGALRegister = PARAMS.yyyy;
		var TYPE:AGALRegister = PARAMS.z;
		var OFFSET:AGALRegister = PARAMS.w;

		// 基本演算用
		var NUMS:AGALRegister = ft7;
		var ZERO:AGALRegister = NUMS.x;
		var ONE:AGALRegister = NUMS.y;
		var TWO:AGALRegister = NUMS.z;
		var THREE:AGALRegister = NUMS.w;

		// PMA(premultiplied alpha)演算されているのを元の値に戻す  rgb /= a (お決まりパターン)
		divide(ft0.xyz, ft0.xyz, ft0.www);

		// 座標値取得
		move(ft1, v1);

		// オフセット移動 (MATRIXにはいれていない)
		add(ft1.x, ft1.x, OFFSET);

		// 少数部分破棄 (お決まりパターン)
		fractional(ft2, ft1);
		subtract(ft1, ft1, ft2);

		// DISTANCEで割った余りを求める
		divide(ft2, ft1, DISTANCE_xyzw); // ex) 8.0 / 3.0 = 2.6666
		fractional(ft3, ft2); // ex) 2.6666 -> 0.6666
		subtract(ft2, ft2, ft3); // ex) 2.6666 - 0.6666 = 2.0
		multiply(ft2, ft2, DISTANCE_xyzw); // ex) 2.0 * 3.0 = 6.0;
		subtract(ft2, ft1, ft2); // ex) 8.0 - 6.0 = 2.0

		// 指示があれば左右反転
		subtract(ft3.y, DISTANCE, ONE); // 計算を合わすため、1ずらす
		multiply(ft3.x, TYPE, ft3.y); // 0 or distance
		subtract(ft2.x, ft2.x, ft3.x); // ex) 2 - 3 = -1;
		absolute(ft2.x, ft2.x); // ex) => 1;

		// 描画フラグ
		add(ft2.z, ft2.x, ft2.y); // ex) z = (x % N) + (y % N)
		subtract(ft2.w, DISTANCE, ONE); // ex) distance - 1.0
		setIfNotEqual(ft2.z, ft2.z, ft2.w);

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