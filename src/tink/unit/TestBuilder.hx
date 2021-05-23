package tink.unit;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using Lambda;
using tink.CoreApi;
#if macro
import tink.macro.BuildCache;
using tink.MacroApi;
#end

class TestBuilder {
	
	static var cache = new TypeMap();
	static var infos = new TypeMap();
	static var counter = 0;
	
	public static function build() {
		return BuildCache.getType('tink.unit.TestSuiteBuilder', function(ctx) {
			var type = ctx.type;
			var clsname = ctx.name;
			var info = process(type);
			var cases = [];
			var fields = [];
			var includeMode = false;
			var runnables = [
				Setup => [],
				Teardown => [],
				Before => [],
				After => [],
			];
			
			for(field in info.fields) {
				var fname = field.field.name;
				var cname = switch info.type {
					case TInst(_.get() => {name: name}, _): name;
					default: null;
				}
				
				switch [field.kind, field.variants] {
					case [Test, []]:
						var args = field.bufferIndex == -1 ? [] : [macro new tink.unit.AssertionBuffer()];
						cases.push({
							name: field.description,
							description: null,
							timeout: field.timeout,
							exclude: field.exclude,
							include: field.include,
							condition: field.condition,
							pos: transformPos(field.field.pos, {methodName: fname, className: cname}),
							runnable: macro @:pos(field.field.pos) function():tink.testrunner.Assertions return target.$fname($a{args}),
						});
						
					case [Test, variants]:
						for(v in variants) {
							var args = v.args.copy();
							if(field.bufferIndex != -1) args.insert(field.bufferIndex, macro new tink.unit.AssertionBuffer());
							cases.push({
								name: field.description,
								description: v.description,
								timeout: field.timeout,
								exclude: field.exclude,
								include: field.include,
								condition: field.condition,
								pos: transformPos(v.pos, {methodName: fname, className: cname}),
								runnable: macro @:pos(field.field.pos) function():tink.testrunner.Assertions return target.$fname($a{args}),
							});
							
						}
					
					default:
						var name = 'run_$fname';
						fields.push({
							name: name,
							access: [APublic],
							kind: FFun({
								args: [],
								ret: macro:tink.core.Promise<tink.core.Noise>,
								expr: macro @:pos(field.field.pos) return target.$fname(),
							}),
							pos: field.field.pos,
						});
						runnables[field.kind].push(macro $i{name});
				}
			}
			
			cases = cases.filter(function(c) return !c.exclude && (!includeMode || c.include));
			var tinkCases = [];
			for(i in 0...cases.length) {
				var caze = cases[i];
				if(!includeMode && caze.include) includeMode = true;
				var info = macro {
					name: $v{caze.name},
					description: $v{caze.description},
					pos: {
						lineNumber: $v{caze.pos.lineNumber},
						fileName: $v{caze.pos.fileName},
						methodName: $v{caze.pos.methodName},
						className: $v{caze.pos.className},
					}
				}
				tinkCases.push(macro {
					var pos = {
						lineNumber: $v{caze.pos.lineNumber},
						fileName: $v{caze.pos.fileName},
						methodName: $v{caze.pos.methodName},
						className: $v{caze.pos.className},
					}
					new tink.unit.TestCase($info, ${caze.runnable}, $v{caze.timeout}, $v{caze.include}, $v{caze.exclude} || !${caze.condition}, pos);
				});
			}
			
			var noiseExpr = macro tink.core.Promise.NOISE;
			function makeServiceLoop(f:Array<Expr>) {
				if(f.length == 0) return noiseExpr;
				var fields = f.copy();
				fields.reverse(); // because the call tree is inside-out
				var expr = fields.fold(function(f, expr) return macro $f().handle(function(o) switch o {
					case Success(_): $expr;
					case Failure(e): cb(tink.core.Outcome.Failure(e));
				}), macro cb(tink.core.Outcome.Success(tink.core.Noise.Noise.Noise)));
				return macro tink.core.Future #if (tink_core >= "2") .irreversible #else .async #end(function(cb) $expr);
			}
			
			var ct = type.toComplex();
			var pos = transformPos(type.getPosition().sure(), {className: type.getID()});
			var def = macro class $clsname extends tink.unit.TestSuite.TestSuiteBase<$ct> {
				
				public function new(target:$ct, ?name:String) {
					this.target = target;
					super({
						name: name == null ? $v{info.name} : name,
						pos: {
							lineNumber: $v{pos.lineNumber},
							fileName: $v{pos.fileName},
							methodName: $v{pos.methodName},
							className: $v{pos.className},
						}
					} , $a{tinkCases});
				}
			}
			
			// override service functions
			for(kind in [Setup, Before, After, Teardown])
				switch makeServiceLoop(runnables[kind]) {
					case e if (e != noiseExpr):
						var func = kind.getName().toLowerCase();
						def.fields.push((macro class {override function $func() return $e; }).fields[0]);
					case _:
				}
			
			def.fields = def.fields.concat(fields); 
			def.pack = ['tink', 'unit'];
			
			return def;
		});
	}
	
	static function process(type:Type):TestInfo {
		if(!infos.exists(type)) {
			
			var cls = switch type {
				case TInst(_.get() => cls, _): cls;
				default: throw 'assert';
			}
			
			var suiteName = switch cls.meta.extract(':name') {
				case []: cls.name;
				case [{params: [p]}]: p.getString().sure();
				case v: v[0].pos.error('Expected only one @:name metadata with exactly one parameter');
			}
			
			var fields = [];
			var clstimeout = 5000;
			
			if(cls.superClass != null) {
				var s = cls.superClass.t.get();
				var sinfo = process(Context.getType('${s.module}.${s.name}'));
				clstimeout = sinfo.timeout;
				fields = sinfo.fields.copy();
			}
			
			clstimeout = getTimeout(cls.meta, clstimeout);
					
			for(field in cls.fields.get()) if(field.isPublic && field.kind.match(FMethod(_))) {
				var fname = field.name;
				
				var kind:Kind = null;
				function checkKind(meta:String, k:Kind, ?alt:String) switch field.meta.extract(meta) {
					case []: // ok
					case v if(kind == null):
						kind = k;
						if(alt != null) Context.warning('@$meta is depcreated, use @$alt instead', v[0].pos);
					case v if(kind == k): 
						// duplicate, but ok
						if(alt != null) Context.warning('@$meta is depcreated, use @$alt instead', v[0].pos);
					case v:
						v[0].pos.error('Cannot declare @$meta and @:${Std.string(kind).toLowerCase()} on the same function');
				}
				checkKind(':setup', Setup);
				checkKind(':startup', Setup, ':setup');
				checkKind(':teardown', Teardown);
				checkKind(':shutdown', Teardown, ':teardown');
				checkKind(':before', Before);
				checkKind(':after', After);
				if(kind == null) kind = Test;
				
				switch field.meta.extract(':benchmark') {
					case []: // ok
					case _: field.pos.warning('Did you forget to implement tink.unit.Benchmark, which enables the @:benchmark metadata?');
				}
				
				var description = switch field.meta.extract(':describe') {
					case []: fname;
					case v: [for(v in v) v.params[0].getString().sure()].join('\n');
				}
				var timeout = getTimeout(field.meta, clstimeout);
				
				function subst(e:Expr)
					return switch e {
						case macro this.$field: 
							macro @:pos(e.pos) @:privateAccess this.target.$field;
						case macro this: 
							macro @:pos(e.pos) @:privateAccess this.target;
						default:
							e.map(subst);
					}
				var condition = getCondition(field.meta, subst);
				var variants = switch field.meta.extract(':variant') {
					case []: [];
					case v: 
						var ret = [];
						for(v in v) {
							var desc, args;
							switch v.params {
								case [{expr: ECall({expr: EConst(CString(str))}, params)}]: 
									desc = str;
									args = params.map(subst);
								case p: 
									desc = [for(e in p) e.toString()].join(', ');
									args = p.map(subst);
							}
							ret.push({description: desc, pos: v.pos, args: args});
						}
						ret;
				}
				
				var exclude = field.meta.extract(':exclude').length > 0;
				var include = field.meta.extract(':include').length > 0;
				
				// inject AssertionBuffer
				var bufferIndex = -1;
				function prepareBuffer(type) {
					switch type {
						case TFun(args, ret):
							for(i in 0...args.length)
								switch args[i].t.reduce() {
									case TDynamic(null) | TAbstract(_.get() => {name: 'Any', pack: []}, _): // ignore
									case t if(Context.unify(t, Context.getType('tink.unit.AssertionBuffer'))):
										bufferIndex = i;
										break;
									default:
								}
						case TLazy(f): prepareBuffer(f());
						default:
					}
				}
				prepareBuffer(field.type);
				
				fields.push({
					field: field,
					kind: kind,
					include: include,
					exclude: exclude,
					condition: condition,
					variants: variants,
					bufferIndex: bufferIndex,
					description: description,
					timeout: timeout,
				});
			}
			
			infos.set(type, {
				type: type,
				name: suiteName,
				timeout: clstimeout,
				fields: fields,
			});
		}
		
		return infos.get(type);
	}
	
	static function getCondition(meta:MetaAccess, substThis:Expr->Expr)
		return switch meta.extract(':condition') {
			case []: macro true;
			case [{params: [expr]}]: substThis(expr);
			case p: p[0].pos.error('Multiple @:condition meta');
		} 
	
	static function getTimeout(meta:MetaAccess, defaultValue:Int)
		return switch meta.extract(':timeout') {
			case []: defaultValue;
			case [v]: switch v.params {
					case [{expr: EConst(CInt(i))}]: Std.parseInt(i);
					case [{pos: pos}]: pos.error('Expected integer parameter for @:timeout');
					default: v.pos.error('Expected exactly one parameter for @:timeout');
				}
			case p: p[0].pos.error('Multiple @:timeout meta');
		} 
	
	static function transformPos(p:Position, ?overrides:PosInfoOverrides):haxe.PosInfos 
		return 
			switch Context.getTypedExpr(Context.typeExpr(macro @:pos(p) (function (?pos:haxe.PosInfos) return pos.lineNumber)())) {
				case macro $_({ fileName: $f, lineNumber: $l, className: $c, methodName: $m }):
					if(overrides == null) overrides = {}
					inline function get<T>(overridden:T, base:T) return overridden == null ? base : overridden;
					{ 
						fileName: get(overrides.fileName, f.getString().sure()), 
						lineNumber: get(overrides.lineNumber, l.getInt().sure()), 
						className: get(overrides.className, null), // FIXME: c.getString().sure() points to the macro callsite (i.e. what haxe.macro.Context refers to)
						methodName: get(overrides.methodName, null), // FIXME: m.getString().sure() points to the macro callsite (i.e. what haxe.macro.Context refers to)
					}
				default: null;
			}

}

private typedef PosInfoOverrides = {
	?fileName:String,
	?lineNumber:Int,
	?className:String,
	?methodName:String,
}

private typedef TestInfo = {
	type:Type,
	name:String,
	timeout:Int,
	fields:Array<{
		field:ClassField,
		kind:Kind,
		include:Bool,
		exclude:Bool,
		condition:Expr,
		variants:Array<{description:String, pos:Position, args:Array<Expr>}>,
		bufferIndex:Int,
		description:String,
		timeout:Int,
	}>,
}

private enum Kind {
	Setup;
	Teardown;
	Before;
	After;
	Test;
}
