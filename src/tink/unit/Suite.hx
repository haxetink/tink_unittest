package tink.unit;

import tink.unit.Case;

using tink.CoreApi;

@:forward
abstract Suite(SuiteObject) from SuiteObject to SuiteObject {
	
	@:from
	public static inline function ofCases<T:Case>(cases:Array<T>):Suite
		return new BasicSuite({
			name: [for(c in cases) switch Type.getClass(c) {
				case null: null;
				case c: Type.getClassName(c);
			}].join(', '),
		}, cast cases);
	
	@:from
	public static inline function ofCase(caze:Case):Suite
		return ofCases([caze]);
}

interface SuiteObject {
	var info:SuiteInfo;
	var cases:Array<Case>;
}

typedef SuiteInfo = {
	name:String,
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

class BasicSuite implements SuiteObject {
	public var info:SuiteInfo;
	public var cases:Array<Case>;
	
	public function new(info, cases) {
		this.info = info;
		this.cases = cases;
	}
}