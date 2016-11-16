package tink.unit;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

#if macro
using tink.MacroApi;
#end
using tink.CoreApi;
using StringTools;

class Macro {
	
	public static function buildRunner() {
		var type = switch Context.getLocalType() {
			case TInst(_, [type]): type;
			default: throw 'assert';
		}
		var cls = switch type {
			case TInst(_.get() => cls, _): cls;
			default: throw 'assert';
		}
		
		// TODO: may need a better way of caching to avoid hash clash
		var clsname = 'Runner_' + Context.signature(cls);
		try return Context.getType('tink.unit.$clsname') catch(e:Dynamic) {}
		
		var tname = (switch cls.meta.extract(':name') {
			case []: Success(cls.name);
			case [{params: [p]}]: p.getString();
			case v: v[0].pos.makeFailure('Expected only one @:name metadata with exactly one parameter');
		}).sure();
		var clstimeout = getTimeout(cls.meta).sure();
		var ct = type.toComplex();
		var tests = [
			Startup => [],
			Shutdown => [],
			Before => [],
			After => [],
			Test => [],
		];
		for(field in cls.fields.get()) if(field.isPublic && field.kind.match(FMethod(_))) {
			var fname = field.name;
			
			var kind:Kind = null;
			function checkKind(meta:String, k:Kind) return switch field.meta.extract(meta) {
				case []: Success(Noise); 
				case v if(kind == null): kind = k; Success(Noise);
				case v: v[0].pos.makeFailure('Cannot declare @$meta and @:${Std.string(kind).toLowerCase()} on the same function');
			}
			checkKind(':startup', Startup).sure();
			checkKind(':shutdown', Shutdown).sure();
			checkKind(':before', Before).sure();
			checkKind(':after', After).sure();
			if(kind == null) kind = Test;
			
			var description = switch field.meta.extract(':describe') {
				case []: [macro $v{fname}];
				case v: [for(v in v) macro $v{v.params[0].getString().sure()}];
			}
			var timeout = getTimeout(field.meta, clstimeout).sure();
			
			var posInfos = Context.getPosInfos(field.pos);
			tests[kind].push(macro @:pos(field.pos) ({
				descriptions: $a{description},
				timeout: $v{timeout},
				run: function() return (function(?pos:haxe.PosInfos) {
					// this part is hacky, because Context.getPosInfos() doesn't give us the line number
					// so we need rely on the compiler to generate the line number for us, then override
					// the values known to us right now
					pos.className = $v{cls.name};
					pos.fileName = $v{posInfos.file};
					pos.methodName = $v{field.name}; 
					return {
						pos: pos,
						result: (test.$fname():tink.unit.TestCase.TestResult),
					}
				})(),
			}:tink.unit.TestCase.Test));
		}
		
		var def = macro class $clsname extends tink.unit.TestRunner.RunnerBase {
			var test:$ct;
			public function new(test) {
				this.test = test;
				name = $v{tname};
				startups = $a{tests[Startup]};
				shutdowns = $a{tests[Shutdown]};
				befores = $a{tests[Before]};
				afters = $a{tests[After]};
				tests = $a{tests[Test]};
			}
		}
		def.pack = ['tink', 'unit'];
		
		Context.defineType(def);
		return Context.getType('tink.unit.$clsname');
	}
	
	public static function run(e:Expr) {
		switch e.expr {
			case EArrayDecl(values):
				var expr = [];
				for(v in values) {
					var type = Context.typeof(v);
					var ct = type.toComplex();
					expr.push(macro new tink.unit.TestRunner.Runner<$ct>($v).asRunner());
				}
				return macro {
					var tests = $a{expr};
					tink.unit.TestRunner.runAll(tests);
				}
				
			default: Context.fatalError('Expected Array', e.pos);
		}
		return macro null;
	}
		
	static function getTimeout(meta:MetaAccess, def = 5000)
		return switch meta.extract(':timeout') {
			case []: Success(def);
			case [v]: switch v.params {
					case [{expr: EConst(CInt(i))}]: Success(Std.parseInt(i));
					case [{pos: pos}]: pos.makeFailure('Expected integer parameter for @:timeout');
					default: v.pos.makeFailure('Expected exactly one parameter for @:timeout');
				}
			case p: p[0].pos.makeFailure('Multiple @:timeout meta');
		} 
	
}

enum Kind {
	Startup;
	Shutdown;
	Before;
	After;
	Test;
}
