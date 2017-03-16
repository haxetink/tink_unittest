package tink.unit;

import tink.streams.Stream;

using tink.CoreApi;

interface Case {
	var info:CaseInfo;
	function execute():Stream<Assertion>;
}

typedef CaseInfo = {
	description:String,
}

class BasicCase implements Case {
	
	public var info:CaseInfo;
	var assert:AssertBuffer;
	
	public function new() {
		assert = new AssertBuffer();
	}
	
	public function execute():Stream<Assertion> {
		return assert;
	}
}