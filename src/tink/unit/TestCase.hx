package tink.unit;

import tink.testrunner.Assertions;
import tink.testrunner.Case;
import tink.testrunner.Suite;
import haxe.PosInfos;

using tink.CoreApi;

class TestCase implements CaseObject {
	public var suite:Suite;
	public var info:CaseInfo;
	public var timeout:Int;
	public var include:Bool;
	public var exclude:Bool;
	public var pos:PosInfos;
	
	var test:Void->Assertions;
	
	public function new(info, test, timeout, include, exclude, ?pos:haxe.PosInfos) {
		this.info = info;
		this.test = test;
		this.timeout = timeout;
		this.include = include;
		this.exclude = exclude;
		this.pos = pos;
	}
	
	public function execute():Assertions {
		return test();
	}
	
	
}