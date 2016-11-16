package tink.unit;

using tink.CoreApi;

typedef TestCase = {
	name:String,
	tests:Void->Array<Test>,
}

typedef Test = {
	descriptions:Array<String>,
	timeout:Int,
	run:Void->{pos:haxe.PosInfos, result:TestResult},
}

@:forward
abstract TestResult(Surprise<Noise, Error>) from Surprise<Noise, Error> to Surprise<Noise, Error> {
	#if !macro
	@:from
	public static inline function ofOutcome(v:Outcome<Noise, Error>):TestResult
		return Future.sync(v);
		
	@:from
	public static inline function ofNoise(v:Noise):TestResult
		return ofOutcome(Success(v));
		
	@:from
	public static inline function ofFuture(v:Future<Noise>):TestResult
		return v.map(function(r) return Success(r));
	
	@:from
	public static inline function ofFutureAssert(v:Future<Assert>):TestResult
		return v >> function(assert:Assert) return Success(assert);
	
	@:from
	public static inline function ofUnsafeAssert(v:Surprise<Assert, Error>):TestResult
		return v >> function(assert:Assert) return assert;
	#end
}