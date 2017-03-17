package tink.unit;

typedef Case = {
	var info:CaseInfo;
	function execute():Assertions;
}

typedef CaseInfo = {
	description:String,
	timeout:Null<Int>, // ms
}