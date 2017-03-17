package tink.unit;

import tink.testrunner.Assertion;
import tink.testrunner.Assertions;
import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Services;

using tink.CoreApi;

class TestCase implements Case {
	public var info:CaseInfo;
	public var timeout:Int;
	public var include:Bool;
	public var exclude:Bool;
	
	var test:Void->Assertions;
	
	public function new(info, test, timeout, include, exclude) {
		this.info = info;
		this.test = test;
		this.timeout = timeout;
		this.include = include;
		this.exclude = exclude;
	}
	
	public function execute():Assertions {
		return test();
	}
	
	
}