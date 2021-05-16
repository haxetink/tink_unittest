package tink.unit;

import tink.testrunner.Assertion;
import tink.testrunner.Assertions;
import tink.streams.Stream;

using Lambda;
#if macro
import haxe.macro.*;
import haxe.macro.Expr;
using tink.MacroApi;
#end

class Assert {
	static var printer = new haxe.macro.Printer();

	public static macro function expectCompilerError(expr:Expr, ?pattern:ExprOf<EReg>, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var error = null;
		try Context.typeof(expr)
		catch (e:Dynamic) {
			error = Std.string(e);
		}

		var ereg = switch pattern {
			case null | macro null: null;
			case { expr: EConst(CString(s)) }: new EReg(s, '');
			case { expr: EConst(CRegexp(r, opt)) }: new EReg(r, opt);
			default: pattern.reject('expected string or regex literal');
		}

		switch description {
			case null | macro null:
				var error = switch error {
					case null: 'no error';
					case v: v;
				}

				description = (
					if (ereg == null) '`${expr.toString()}` should not to compile ($error)';
					else '`${expr.toString()}` should produce error matching ${pattern.toString()} ($error)'
				).toExpr();
			default:
		}

		var ok = error != null && (ereg == null || ereg.match(error));
		
		var args = [macro @:pos(expr.pos) $v{ok}, description];
		switch pos {
			case macro null: // skip
			case v: args.push(v);
		}

		return macro tink.unit.Assert.assert($a{args});
	}

	public static macro function assert(expr:ExprOf<Bool>, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var pre = macro {};
		var assertion = expr;

		switch description {
			case macro null:
			default:
				if(Context.unify(Context.typeof(description), Context.getType('haxe.PosInfos'))) {
					pos = description;
					description = macro null;
				}
		}

		switch description {
			case macro null:
				description = macro $v{expr.toString()};

				// TODO: we can actually do a recursive breakdown: e.g. `a == 1 && b == 2`
				switch expr {
					case {expr: EBinop(op, e1, e2), pos: pos}:
						switch Context.typeExpr(expr) { // type it as a whole to preserve top-down inference
							case t_expr = {expr: TBinop(t_op, t_e1, t_e2) | TCast({expr: TBinop(t_op, t_e1, t_e2)}, _)}:
								var stored = Context.storeTypedExpr(t_expr);
								var lstored = Context.storeTypedExpr(t_e1);
								var rstored = Context.storeTypedExpr(t_e2);

								var lct = t_e1.t.toComplex();
								var rct = t_e2.t.toComplex();

								pre = macro {
									// store the values to avoid evaluating the expressions twice
									var lh:$lct = $lstored;
									var rh:$rct = $rstored;
								}

								assertion = EBinop(op, macro @:pos(e1.pos) lh, macro @:pos(e2.pos) rh).at(pos);
								description = macro $description + ' (' + ${stringify(macro lh, t_e1.t)} + ' ' + $v{printer.printBinop(op)} + ' ' + ${stringify(macro rh, t_e2.t)} + ')';
							case v:
								var lt = Context.typeof(e1);
								var rt = Context.typeof(e2);

								function isAbstract(t:Type)
									return t.reduce().match(TAbstract(_));

								if (!(isAbstract(lt) || isAbstract(rt)))
									expr.pos.warning('Please report this to tink_unittest: Unhandled TypedExpr: $v');

								var lct = lt.toComplex();
								var rct = rt.toComplex();

								pre = macro {
									// store the values to avoid evaluating the expressions twice
									var lh = $e1;
									var rh = $e2;
								}

								assertion = EBinop(op, macro @:pos(e1.pos) (lh:$lct), macro @:pos(e2.pos) (rh:$rct)).at(expr.pos);
								description = macro $description + ' (' + ${stringify(macro lh, lt)} + ' ' + $v{printer.printBinop(op)} + ' ' + ${stringify(macro rh, rt)} + ')';
						}

					case macro $e1.match($e2):
						pre = macro {
							var value = $e1;
						}
						assertion = macro @:pos(expr.pos) value.match($e2);
						description = macro $description + ' (' + $v{e1.toString()} + ' => ' + ${stringify(macro value, Context.typeof(e1))} + ')';
					default:
				}
			default:
		}

		var args = [assertion, description];
		switch pos {
			case macro null: // skip
			case v: args.push(v);
		}
		return pre.concat(macro @:pos(expr.pos) new tink.testrunner.Assertion($a{args}));
	}

	#if deep_equal

	public static macro function compare(expected:Expr, actual:Expr, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {

		var pre = macro {
			@:pos(expected.pos) var expected:Dynamic = $expected;
			@:pos(actual.pos) var actual:Dynamic = $actual;
		}

		var args = [
			macro deepequal.DeepEqual.compare(expected, actual),
			switch description {
				case macro null: macro '\nExpected : ' + expected + '\nActual   : ' + actual;
				case v: v;
			}
		];
		switch pos {
			case macro null:
			case _: args.push(pos);
		}

		var pos = Context.currentPos();
		return pre.concat(macro @:pos(pos) new tink.testrunner.Assertion($a{args}));
	}

	#end

	public static macro function benchmark(iterations:ExprOf<Int>, body:Expr):ExprOf<tink.testrunner.Assertion> {
		return macro @:pos(body.pos) {
			var __iter = $iterations;
			var __start = haxe.Timer.stamp();
			for(_ in 0...__iter) $body;
			var __dt = haxe.Timer.stamp() - __start;
			var __str = Std.string(__dt * 1000);
			if(__str == '0') __str = '0.000001';
			else switch __str.indexOf('.') {
				case -1: // ok
				case index: __str = __str.substr(0, index + 7);
			}
			new tink.testrunner.Assertion(true, 'Benchmark: ' + __iter + ' iterations = ' + __str + ' ms');
		}
	}
	
	#if macro
	static function stringify(e:Expr, t:haxe.macro.Type) {
		return switch t {
			case _.getID() => 'String':
				macro '"' + ($e:String) + '"';
			case TAbstract(_.get() => {name: name, to: to}, _) if(to.exists(function(v) return v.t.getID() == 'String' && v.field == null)): // "to String"
				macro '"' + ($e:String) + '"';
			case TAbstract(_.get() => {name: name, to: to}, _) if(to.exists(function(v) return v.t.getID() == 'String' && v.field != null)):  // "@:to String"
				macro ($e:String);
			case _:
				macro Std.string($e);
		}
	}
	#end
	
	#if !macro
	public static inline function fail(e:tink.core.Error, ?pos:haxe.PosInfos):Assertions
		return Stream.ofError(e);
	#end
}
