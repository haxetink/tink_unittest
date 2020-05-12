package tink.unit;

import tink.testrunner.Assertion;
import tink.testrunner.Assertions;
import tink.streams.Stream;
import haxe.macro.Expr;
import haxe.macro.Context;

#if macro
using tink.MacroApi;
#end

class Assert {
	static var printer = new haxe.macro.Printer();
	
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
									var lh = $lstored;
									var rh = $rstored;
								}
		
								assertion = EBinop(op, macro @:pos(e1.pos) lh, macro @:pos(e2.pos) rh).at(pos);
								description = macro $description + ' (' + tink.unit.Assert.stringify(lh) + ' ' + $v{printer.printBinop(op)} + ' ' + tink.unit.Assert.stringify(rh) + ')';
							case v:
								expr.pos.warning('Please report this to tink_unittest: Unhandled TypedExpr: $v');
								
								var lct = Context.typeof(e1).toComplex();
								var rct = Context.typeof(e2).toComplex();
								
								pre = macro {
									// store the values to avoid evaluating the expressions twice
									var lh = $e1; 
									var rh = $e2;
								}
								
								assertion = EBinop(op, macro @:pos(e1.pos) (lh:$lct), macro @:pos(e2.pos) (rh:$rct)).at(expr.pos);
								description = macro $description + ' (' + tink.unit.Assert.stringify(lh) + ' ' + $v{printer.printBinop(op)} + ' ' + tink.unit.Assert.stringify(rh) + ')';
						}

					case macro $e1.match($e2):
						pre = macro {
							var value = $e1;
						}
						assertion = macro @:pos(expr.pos) value.match($e2);
						description = macro $description + ' (' + $v{e1.toString()} + ' => ' + tink.unit.Assert.stringify(value) + ')';
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
	
	#if !macro
	public static function fail(e:tink.core.Error, ?pos:haxe.PosInfos):Assertions
		return #if pure Stream.ofError(e) #else Stream.failure(e) #end;
	
	public static function stringify(v:Dynamic) {
		return 
			if(Std.is(v, String) || Std.is(v, Float) || Std.is(v, Bool)) haxe.Json.stringify(v);
			else Std.string(v);
	}
	#end
}
