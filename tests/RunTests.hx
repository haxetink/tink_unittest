package;

import tink.testrunner.Runner;
import tink.testrunner.Assertion;
import tink.unit.Assert.assert;
import tink.unit.TestBatch;
import travix.Logger.*;

using tink.CoreApi;

class RunTests {
	static function main() {
		
		var code = 0;
		
		#if (cs || java) // https://github.com/HaxeFoundation/haxe/issues/6106
		function assertEquals(expected:Dynamic, actual:Dynamic, ?pos:haxe.PosInfos) {
		#else
		function assertEquals<T>(expected:T, actual:T, ?pos:haxe.PosInfos) {
		#end
			if(expected != actual) {
				println('${pos.fileName}:${pos.lineNumber}: Expected $expected but got $actual ');
				code++;
			}
		}
		
		var futures = [];
		
		// Test: basic
		var normal = new NormalTest();
		var _await = new AwaitTest();
		var exclude = new ExcludeTest();
		var grandParent = new GrandParentTest();
		var parent = new ParentTest();
		var child = new ChildTest();
		futures.push(
			function() return Runner.run(TestBatch.make([
				normal,
				_await,
				exclude,
				grandParent,
				parent,
				child,
			])).map(function(result) {
				assertEquals(0, result.summary().failures.length);
				assertEquals('ss2bb2syncaa2bb2syncAssertaa2bb2asyncaa2bb2asyncAssertaa2bb2timeoutaa2bb2nestedDescriptionsaa2bb2multiAssertaa2bb2variant1aa2bb2variant2aa2bb2variant3aa2dd2', normal.result);
				assertEquals('ss2bb2asyncaa2dd2', _await.result);
				assertEquals('ss2bb2includeaa2dd2', exclude.result);
				assertEquals('ss2grandParentdd2', grandParent.result);
				assertEquals('ss2bb2grandParentaa2bb2parentaa2dd2', parent.result);
				assertEquals('ss2bb2grandParentaa2bb2parentaa2bb2childaa2dd2', child.result);
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
				assertEquals(0, result.summary().failures.length);
				assertEquals('', normal.result);
				assertEquals('', _await.result);
				assertEquals('ss2bb2includeaa2dd2', include.result);
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

@:asserts
@:name('Custom Test Name')
class NormalTest {
	public var myInt = 3;
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
		return new Assertion(true, 'Always true');
	}

	@:describe('Sync test using Assert')
	public function syncAssert() {
		debug('syncAssert');
		return assert(true);
	}
		
	@:describe('Async test')
	public function async() {
		debug('async');
		return Future.sync(new Assertion(true, 'Always true'));
	}
		
	@:describe('Async test using Assert')
	public function asyncAssert() {
		debug('asyncAssert');
		return Future.sync(assert(true));
	}
		
	@:timeout(1500) // in ms
	@:describe('Timeout test')
	public function timeout() {
		debug('timeout');
		return Future.async(function(cb) haxe.Timer.delay(function() cb(assert(true)), 1000));
	}
		
	@:describe('Nest')
	@:describe('  your')
	@:describe('    descriptions')
	public function nestedDescriptions() {
		debug('nestedDescriptions');
		return assert(true);
	}
    
	@:describe('Multiple assertions')
	public function multiAssert() {
		debug('multiAssert');
		
		var timer = new haxe.Timer(500);
		var i = 0;
		timer.run = function()
			if(i++ < 3) asserts.assert(true);
			else {
				asserts.done();
				timer.stop();
			}
		return asserts;
	}
	
	@:describe('Variants')
	@:variant("One and One"(1, 1))
	@:variant(2, 2)
	@:variant("Access this"(target.myInt, 3))
	public function variant(a:Int, b:Int) {
		debug('variant$a');
		return assert(a == b);
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
		return assert(actual == 'actual');
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
		var value = 1;
		return assert(value == 1);
	}

	public function skip() {
		debug('skip');
		return assert(true);
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
		return assert(true);
	}

	public function include() {
		debug('include');
		return assert(true, 'Included');
	}
}

class GrandParentTest {
	public var result:String;
	
	public function new() {
		result = '';
	}
	
	function debug(msg:String) {
		result += msg;
		return Noise;
	}
	@:startup public function startup() return debug('s');
	@:startup public function startup2() return debug('s2');
	@:shutdown public function shutdown() return debug('d');
	@:shutdown public function shutdown2() return debug('d2');
		
	
	public function grandParent() {
		debug('grandParent');
		return assert(true);
	}
}

class ParentTest extends GrandParentTest {
	
	@:before public function before() return debug('b');
	@:before public function before2() return debug('b2');
	@:after public function after() return debug('a');
	@:after public function after2() return debug('a2');
		
	
	public function parent() {
		debug('parent');
		return assert(true);
	}
}

class ChildTest extends ParentTest {
	public function child() {
		debug('child');
		return assert(true);
	}
}