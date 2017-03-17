package tink.unit;

interface Case {
	var info:CaseInfo;
	function execute():Assertions;
}

typedef CaseInfo = {
	description:String,
	timeout:Null<Int>, // ms
}

class BasicCase implements Case {
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