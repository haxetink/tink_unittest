package tink.unit;

import tink.streams.Stream;

typedef Suite = {
	var info:SuiteInfo;
	var cases:Array<Case>;
}

typedef SuiteInfo = {
	name:String,
}