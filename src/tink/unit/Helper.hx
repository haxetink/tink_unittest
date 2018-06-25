package tink.unit;

import haxe.Timer;

using tink.CoreApi;

class Helper {
	public static inline function seq(arr)
		return Promise.inSequence(arr);
	
	public static function lazy<T>(gen:Void->Promise<T>, ?handler:T->Void):Promise<Noise>
		return Promise.lazy(gen).next(function(v) {
			if(handler != null) handler(v);
			return Noise;
		});
	
	public static function delay(ms:Int):Future<Noise>
		return Future.async(function(cb) Timer.delay(cb.bind(Noise), ms));
	
}