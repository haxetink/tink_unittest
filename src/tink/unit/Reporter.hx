package tink.unit;

interface Reporter {
	function log(v:String):Void;
}

class SimpleReporter implements Reporter {
	public function new() {}
	public function log(msg:String) 
		#if travix
			travix.Logger.println(msg);
		#elseif js
			untyped console.log(msg);
		#elseif sys
			Sys.println(msg);
		#end
}