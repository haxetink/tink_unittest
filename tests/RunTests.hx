import tink.unit.TestRunner.*;
import tink.unit.Assert.*;
using tink.CoreApi;

class RunTests {
	static function main() {
		var normal = new NormalTest();
		var await = new AwaitTest();
		run([
			normal,
			await,
		]).handle(function(result) {
			var code = result.errors;
			// trace(normal.result);
			// trace(await.result);
			if(normal.result != 'ss2bb2syncaa2bb2syncAssertaa2bb2asyncaa2bb2asyncAssertaa2bb2timeoutaa2bb2nestedDescriptionsaa2bb2multiAssertaa2dd2') code++;
			if(await.result != 'ss2bb2asyncaa2dd2') code++;
			exit(code);
		});
	}
}

@:name('Custom Test Name')
class NormalTest {
	public var result:String;
	
	public function new() {
		result = '';
	}
	
	function debug(msg:String) {
		result += msg;
		return Noise;
	}
	
	@:before public function before() return debug('b');
	@:before public function before2() return debug('b2');
	@:after public function after() return debug('a');
	@:after public function after2() return debug('a2');
	@:startup public function startup() return debug('s');
	@:startup public function startup2() return debug('s2');
	@:shutdown public function shutdown() return debug('d');
	@:shutdown public function shutdown2() return debug('d2');
		
	@:describe('Sync test')
	public function sync() {
		debug('sync');
		return true ? Success(Noise) : Failure(new Error('Errored!'));
	}


	@:describe('Test using Assert')
	public function syncAssert() {
		debug('syncAssert');
		return isTrue(true);
	}
		
	@:describe('Async test')
	public function async() {
		debug('async');
		return Future.sync(true ? Success(Noise) : Failure(new Error('Errored!')));
	}
		
	@:describe('Async test using Assert')
	public function asyncAssert() {
		debug('asyncAssert');
		return Future.sync(isTrue(true));
	}
		
	@:timeout(1500) // in ms
	@:describe('Timeout test')
	public function timeout() {
		debug('timeout');
		return Future.async(function(cb) haxe.Timer.delay(function() cb(isTrue(true)), 1000));
	}
		
	@:describe('Nest')
	@:describe('  your')
	@:describe('    descriptions')
	public function nestedDescriptions() {
		debug('nestedDescriptions');
		return isTrue(true);
	}
    
	@:describe('Multiple assertions')
	public function multiAssert() {
		debug('multiAssert');
		return isTrue(true) && isTrue(true) && isTrue(true);
	}
}

@:await
class AwaitTest {
	public var result:String;
	
	public function new() {
		result = '';
	}
	
	function debug(msg:String) {
		result += msg;
		return Noise;
	}
	
	@:before public function before() return debug('b');
	@:before public function before2() return debug('b2');
	@:after public function after() return debug('a');
	@:after public function after2() return debug('a2');
	@:startup public function startup() return debug('s');
	@:startup public function startup2() return debug('s2');
	@:shutdown public function shutdown() return debug('d');
	@:shutdown public function shutdown2() return debug('d2');
	
	@:describe('Async test powered by tink_await')
	@:async public function async() {
		debug('async');
		var actual = @:await someAsyncValue();
		return equals('actual', actual);
	}
  
  function someAsyncValue() 
    return Future.async(function(cb) haxe.Timer.delay(function() cb('actual'), 1000));
}