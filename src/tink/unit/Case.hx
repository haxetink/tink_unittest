package tink.unit;

import tink.streams.Stream;
import tink.unit.Suite;

using tink.CoreApi;

interface Case {
	var info:CaseInfo;
	function execute():Assertions;
}

typedef CaseInfo = {
	description:String,
}

class TinkCase implements Case {
	public var info:CaseInfo;
	
	var befores:Services;
	var afters:Services;
	var test:Void->Stream<Assertion>;
	
	public function new(info, befores, afters, test) {
		this.info = info;
		this.befores = befores;
		this.afters = afters;
		this.test = test;
	}
	
	public function execute():Assertions {
		return befores.run()
			.next(function(_) return test())
			.next(function(result) return afters.run().next(function(_) return result));
	}
	
	
}