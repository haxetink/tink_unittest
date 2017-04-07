package tink.unit;

import tink.testrunner.*;
import tink.streams.Accumulator;
import haxe.macro.Expr;

#if macro
using haxe.macro.Expr;
using haxe.macro.Type;
using tink.MacroApi;
using Lambda;
#end

abstract AssertionBuffer(Accumulator<Assertion, tink.core.Error>) to Assertions {
	public inline function new()
		this = new Accumulator();
		
	public macro function assert(ethis:Expr, expr:ExprOf<Bool>, ?description:String):ExprOf<Assertion> {
		return macro $ethis.emit(tink.unit.Assert.assert($expr, $v{description}));
	}
		
	public inline function emit(assertion:Assertion)
		this.yield(Data(assertion));
	
	public inline function done():Assertions {
		this.yield(End);
		return this;
	}
}

#if macro
class AssertionBufferInjector {
	public static function use() {
		function appliesTo(m:MetaAccess) return m.has(':asserts');
		SyntaxHub.classLevel.before(
			function (_) return true,
			function (c: ClassBuilder) {
				if (c.target.isInterface && !appliesTo(c.target.meta))
					return false;
				
				if (!appliesTo(c.target.meta)) {
					for (i in c.target.interfaces)
						if (appliesTo(i.t.get().meta)) {
							applyTo(c);
							return true;
						}
					var s = c.target.superClass;
					while(s != null) {
						var sc = s.t.get();
						if(appliesTo(sc.meta)) {
							applyTo(c);
							return true;
						}
						s = sc.superClass;
					}
					return false;
				}
				else {
					applyTo(c);
					return true;
				}
			}
		);
	}
	
	static function applyTo(builder:ClassBuilder) {
		for(member in builder) {
			
			function isTest(member:Member) {
				var meta = member.asField().meta;
				return !meta.exists(function(m) return m.name == ':startup' || m.name == ':shutdown' || m.name == ':before' || m.name == ':after');
			}
			
			if(member.isPublic && isTest(member))
				switch member.getFunction() {
					case Success(func):
						if(func.args.exists(function(a) return a.name == 'asserts'))
							haxe.macro.Context.warning('Skip injecting AssertionBuffer because there is already an argument named "asserts"', member.pos);
						else
							func.args.push({
								name: 'asserts',
								type: macro:tink.unit.AssertionBuffer,
							});
					case Failure(_): // skip
				}
		}
	}
}
#end