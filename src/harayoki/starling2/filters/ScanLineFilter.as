package harayoki.starling2.filters {

	import starling.animation.IAnimatable;
	import starling.filters.FragmentFilter;
	import starling.rendering.FilterEffect;

	public class ScanLineFilter extends FragmentFilter implements IAnimatable
	{
		private var _scale:Number = 1.0;
		private var _degree:Number = 0.0;
		private var _distance:int = 1;
		private var _offset:Number = 0.0;
		private var _color:uint = 0;
		private var _alpha:Number = 1.0;

		public var timeScale:Number = 1.0;

		public function ScanLineFilter(
			scale:Number=2.0, degree:Number=0.0, distance:int=1, color:uint=0x000000, alpha:Number=1.0):void
		{
			_scale = scale < 1.0 ? 1.0 : scale;
			_degree = degree % 360;
			slashShadedEffect.updateMatrix(_degree, _scale);
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
			return new ScanLineEffect();
		}

		private function get slashShadedEffect():ScanLineEffect
		{
			return effect as ScanLineEffect;
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

		public function get scale():Number { return _scale; }
		public function set scale(value:Number):void
		{
			value = value < 1.0 ? 1.0 : value;
			if(_scale != value) {
				_scale = value;
				slashShadedEffect.updateMatrix(_degree, _scale);
				setRequiresRedraw();
			}
		}

		public function get degree():Number { return _degree; }
		public function set degree(value:Number):void
		{
			value = value % 360;
			if(_degree != value) {
				_degree = value;
				slashShadedEffect.updateMatrix(_degree, _scale);
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

		public function get distance():Number { return _distance; }
		public function set distance(value:Number):void
		{
			//５より大きいと表示が荒れる
			if(Math.abs(value) > 5) {
				value = value < 0 ? -5 : 5;
			}
			if(_distance != value) {
				_distance = value;
				slashShadedEffect.distance = _distance;
				setRequiresRedraw();
			}
		}

		// アスペクト比設定 ->
		//private var _aspect:Number = 1.0;
		//public function get aspect():Number { return _aspect; }
		//public function set aspect(value:Number):void
		//{
		//	if(_aspect != value) {
		//		_aspect = value;
		//		slashShadedEffect.aspect = _aspect;
		//		setRequiresRedraw();
		//	}
		//}

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

internal class ScanLineEffect extends FilterEffect
{
	private var _color:Vector.<Number>;
	private var _vars:Vector.<Number>;
	private var _mat:Matrix3D;

	public function ScanLineEffect()
	{
		_color = new Vector.<Number>(4, true);
		_mat = new Matrix3D();
		_vars = new <Number>[0, 1, 1, 0];
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
		trace("");
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
		if (value < 0) {
			value--;
		} else if (value > 0) {
			value++
		}
		_vars[1] = value;

		//描画エリアを反転しない場合1 する場合0
		_vars[2] = value >= 0 ? 1 : 0;
	}

	public function set offset(value:Number):void {
		_vars[3] = value;
	}

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

		// tex ft0, v0, fs0 <2d, ****>

		var FILL_COLOR:AGALRegisterConstant  = fc0;
		var MATRIX:AGALRegisterConstant     = fc2;

		move(ft7, fc1); // 定数同士の演算エラーになるのをさけるためftに取り出す (お決まりパターン)

		var ZERO:AGALRegister = ft7.x;
		var DISTANCE:AGALRegister = ft7.y;
		var DISTANCE_xyzw:AGALRegister = ft7.yyyy;
		var NOT_REVERSE:AGALRegister = ft7.z;
		var OFFSET:AGALRegister = ft7.w;

		// PMA(premultiplied alpha)演算されているのを元の値に戻す  rgb /= a (お決まりパターン)
		divide(ft0.xyz, ft0.xyz, ft0.www);

		// 座標値取得
		move(ft1, v1);

		// 拡大回転
		multiplyMatrix3x3(ft1.xyz, ft1.xyz, MATRIX);

		// オフセット移動 (MATRIXにはいれていない)
		add(ft1.y, ft1.y, OFFSET);

		// 少数部分破棄 (お決まりパターン)
		fractional(ft2, ft1);
		subtract(ft1, ft1, ft2);

		// ON / OFF 判定
		divide(ft2, ft1, DISTANCE_xyzw);
		fractional(ft2, ft2);
		setIfNotEqual(ft2.z, ft2.y, ZERO); // ON/OFFフラグ

		// 強さ0の時はOFFフラグをなくす
		setIfEqual(ft2.x, DISTANCE, ZERO); // 強さ0か？
		add(ft2.z, ft2.z, ft2.x);// 強さ0の場合 ON/OFFフラグが1か2に
		saturate(ft2.z, ft2.z); // 2を1に変換

		// 描画エリア反転処理 条件により反転 (お決まりパターン)
		setIfEqual(ft2.z, ft2.z, NOT_REVERSE);

		// ON/OFFフラグ反転処理  (お決まりパターン)
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
