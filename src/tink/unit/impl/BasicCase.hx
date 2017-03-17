package tink.unit.impl;

import tink.unit.Case;

class BasicCase {
	public var info:CaseInfo;
	
	public function new() {
		info = {
			description: Type.getClassName(Type.getClass(this)),
			timeout: 5000,
		}
	}
	
	public function execute():Assertions {
		return [].iterator();
	}
}