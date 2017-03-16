package tink.unit;

#if !macro
import tink.streams.Stream;
import tink.unit.Case;

using tink.CoreApi;
#end

@:forward
abstract Suite(SuiteObject) from SuiteObject to SuiteObject {
	
	// public static macro function make(e:haxe.macro.Expr):haxe.macro.Expr.ExprOf<Suite> {
	// 	return Builder.makeSuite(e);
	// }
	
	#if !macro
	@:from
	public static inline function ofCase(caze:Case):Suite
		return {
			info: {
				name: Type.getClassName(Type.getClass(caze)),
			},
			cases: [caze],
		}
	#end
}

typedef SuiteObject = {
	var info:SuiteInfo;
	var cases:Array<Case>;
}

typedef SuiteInfo = {
	name:String,
}

#if !macro
@:genericBuild(tink.unit.Builder.build())
class TinkSuite<T> {}

class TinkSuiteBase<T> {
	public var info:SuiteInfo;
	public var cases:Array<Case>;
	
	var test:T;
	var startups:Services;
	var befores:Services;
	var afters:Services;
	var shutdowns:Services;
	
}

@:forward
abstract Services(Array<Service>) from Array<Service> to Array<Service> {
	public function run():Promise<Noise> {
		return Future.async(function(cb) {
			var iter = this.iterator();
			function next() {
				if(iter.hasNext())
					iter.next()().handle(function(o) if(o.isSuccess()) next() else cb(o));
				else
					cb(Success(Noise));
			}
			next();
		});
	}
}

typedef Service = Void->Promise<Noise>;
#end