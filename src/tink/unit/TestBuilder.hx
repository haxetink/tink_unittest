package tink.unit;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

using Lambda;
using tink.CoreApi;
#if macro
using tink.MacroApi;
#end

class TestBuilder {
	
	static var cache = new TypeMap();
	static var infos = new TypeMap();
	static var counter = 0;
	static var POS_REGEX = ~/#pos([^:]*):([^:]*).*/;
	
	public static function build() {
		switch Context.getLocalType() {
			case TInst(_, [type]): 
				if(!cache.exists(type)) {
					
					var info = process(type);
					var clsname = 'Suite_' + counter++;
					var cases = [];
					var fields = [];
					var includeMode = false;
					var runnables = [
						Startup => [],
						Shutdown => [],
						Before => [],
						After => [],
					];
					
					for(field in info.fields) {
						var fname = field.field.name;
						
						function transformPos(p:Position) {
							return if(POS_REGEX.match(Std.string(p))) {
								lineNumber: Std.parseInt(POS_REGEX.matched(2)),
								fileName: POS_REGEX.matched(1).split('/').pop(),
								methodName: fname,
								className: switch info.type {
									case TInst(_.get() => {name: name}, _): name;
									default: null;
								}
							} else null;
						}
						
						switch [field.kind, field.variants] {
							case [Test, []]:
								var args = field.bufferIndex == -1 ? [] : [macro new tink.unit.AssertionBuffer()];
								cases.push({
									description: field.description,
									timeout: field.timeout,
									exclude: field.exclude,
									include: field.include,
									pos: transformPos(field.field.pos),
									runnable: macro @:pos(field.field.pos) function():tink.testrunner.Assertions return target.$fname($a{args}),
								});
								
							case [Test, variants]:
								for(v in variants) {
									var args = v.args.copy();
									if(field.bufferIndex != -1) args.insert(field.bufferIndex, macro new tink.unit.AssertionBuffer());
									cases.push({
										description: v.description,
										timeout: field.timeout,
										exclude: field.exclude,
										include: field.include,
										pos: transformPos(field.field.pos),
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
										expr: macro return target.$fname(),
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
							description: $v{caze.description},
						}
						tinkCases.push(macro {
							var pos = {
								lineNumber: $v{caze.pos.lineNumber},
								fileName: $v{caze.pos.fileName},
								methodName: $v{caze.pos.methodName},
								className: $v{caze.pos.className},
							}
							new tink.unit.TestCase($info, ${caze.runnable}, $v{caze.timeout}, $v{caze.include}, $v{caze.exclude}, pos);
						});
					}
					
					function makeServiceLoop(f:Array<Expr>) {
						var fields = f.copy();
						fields.reverse();
						var expr = fields.fold(function(f, expr) return macro $f().handle(function(o) switch o {
							case Success(_): $expr;
							case Failure(e): cb(tink.core.Outcome.Failure(e));
						}), macro cb(tink.core.Outcome.Success(tink.core.Noise.Noise.Noise)));
						return macro tink.core.Future.async(function(cb) $expr);
					}
					
					var ct = type.toComplex();
					var def = macro class $clsname extends tink.unit.TestSuite.TestSuiteBase<$ct> {
						
						public function new(target:$ct) {
							super({name: $v{info.name}}, $a{tinkCases});
							this.target = target;
						}
						
						override function startup() return ${makeServiceLoop(runnables[Startup])};
						override function before() return ${makeServiceLoop(runnables[Before])};
						override function after() return ${makeServiceLoop(runnables[After])};
						override function shutdown() return ${makeServiceLoop(runnables[Shutdown])};
					}
					def.fields = def.fields.concat(fields); 
					def.pack = ['tink', 'unit'];
					
					Context.defineType(def);
					cache.set(type, TPath('tink.unit.$clsname'.asTypePath()));
				}
				return cache.get(type);
				
			default: throw 'assert';
		}
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
				function checkKind(meta:String, k:Kind) switch field.meta.extract(meta) {
					case []: // ok
					case v if(kind == null): kind = k;
					case v: v[0].pos.error('Cannot declare @$meta and @:${Std.string(kind).toLowerCase()} on the same function');
				}
				checkKind(':startup', Startup);
				checkKind(':shutdown', Shutdown);
				checkKind(':before', Before);
				checkKind(':after', After);
				if(kind == null) kind = Test;
				
				var description = switch field.meta.extract(':describe') {
					case []: fname;
					case v: [for(v in v) v.params[0].getString().sure()].join('\n');
				}
				var timeout = getTimeout(field.meta, clstimeout);
				var variants = switch field.meta.extract(':variant') {
					case []: [];
					case v: [for(v in v) switch v.params {
						case [{expr: ECall(e, params)}]: {description: '$description: ' + e.getString().sure(), args: params};
						case p: {description: description, args: p}
					}];
				}
				
				var exclude = field.meta.extract(':exclude').length > 0;
				var include = field.meta.extract(':include').length > 0;
				
				// inject AssertionBuffer
				var bufferIndex = -1;
				function prepareBuffer(type) {
					switch type {
						case TFun(args, ret):
							for(i in 0...args.length)
								if(Context.unify(args[i].t, Context.getType('tink.unit.AssertionBuffer'))) {
									bufferIndex = i;
									break;
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
	
	static function getTimeout(meta:MetaAccess, def:Int)
		return switch meta.extract(':timeout') {
			case []: def;
			case [v]: switch v.params {
					case [{expr: EConst(CInt(i))}]: Std.parseInt(i);
					case [{pos: pos}]: pos.error('Expected integer parameter for @:timeout');
					default: v.pos.error('Expected exactly one parameter for @:timeout');
				}
			case p: p[0].pos.error('Multiple @:timeout meta');
		} 
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
		variants:Array<{description:String, args:Array<Expr>}>,
		bufferIndex:Int,
		description:String,
		timeout:Int,
	}>,
}

private enum Kind {
	Startup;
	Shutdown;
	Before;
	After;
	Test;
}
