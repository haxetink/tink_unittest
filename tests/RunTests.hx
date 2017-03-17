package;

import tink.testrunner.Runner;
import tink.unit.Assertion.*;
import tink.unit.TestBatch;
import travix.Logger.*;

using tink.CoreApi;


class RunTests {
	static function main() {
		
		var code = 0;
		
		function oops(?pos:haxe.PosInfos) {
			trace(pos);
			code++;
		}
		
		var futures = [];
		
		// Test: basic
		var normal = new NormalTest();
		var _await = new AwaitTest();
		var exclude = new ExcludeTest();
		futures.push(
			function() return Runner.run(TestBatch.make([
				normal,
				_await,
				exclude,
			])).map(function(result) {
				code += result.errors().length;
				if(normal.result != 'ss2bb2syncaa2bb2syncAssertaa2bb2asyncaa2bb2asyncAssertaa2bb2timeoutaa2bb2nestedDescriptionsaa2bb2multiAssertaa2dd2') oops();
				if(_await.result != 'ss2bb2asyncaa2dd2') oops();
				if(exclude.result != 'ss2bb2includeaa2dd2') oops();
				return Noise;
			})
		);
		
		// Test: include
		var normal = new NormalTest();
		var _await = new AwaitTest();
		var include = new IncludeTest();
		futures.push(
			function() return Runner.run(TestBatch.make([
				normal, 
				_await, 
				include,
			])).map(function(result) {
				code += result.errors().length;
				if(normal.result != '') oops();
				if(_await.result != '') oops();
				if(include.result != 'ss2bb2includeaa2dd2') oops();
				return Noise;
			})
		);
		
		
		var iter = futures.iterator();
		function next() {
			if(iter.hasNext()) iter.next()().handle(next);
			else {
				trace('Exiting with code: $code');
				exit(code);
			}
		}
		next();
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
		
	@:describe("Sync test")
	public function sync() {
		debug('sync');
		return true ? Success(Noise) : Failure(new Error('Errored!'));
	}

	@:describe('Sync test using Assert')
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

class IncludeTest {
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
		
	@:include
	public function include() {
		debug('include');
		return isTrue(true);
	}

	public function skip() {
		debug('skip');
		return isTrue(true);
	}
}

class ExcludeTest {
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
		
	@:exclude
	public function exclude() {
		debug('exclude');
		return isTrue(true);
	}

	public function include() {
		debug('include');
		return isTrue(true);
	}
}