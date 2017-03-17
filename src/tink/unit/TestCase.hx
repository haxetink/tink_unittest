package tink.unit;

import tink.testrunner.Assertion;
import tink.testrunner.Assertions;
import tink.testrunner.Case;
import tink.testrunner.Suite;

using tink.CoreApi;

class TestCase implements Case {
	public var info:CaseInfo;
	
	var befores:Services;
	var afters:Services;
	var test:Void->Assertions;
	var includeMode:Ref<Bool>;
	var include:Bool;
	
	public function new(info, befores, afters, test, includeMode, include) {
		this.info = info;
		this.befores = befores;
		this.afters = afters;
		this.test = test;
		this.includeMode = includeMode;
		this.include = include;
	}
	
	public function execute():Assertions {
		if(includeMode.value && !include) return [].iterator();
		return befores.run()
			.next(function(_) return test())
			.next(function(result) return afters.run().next(function(_) return result));
	}
	
	
}