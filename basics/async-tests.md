# Async Tests

In addition to the ways [mentioned](https://haxetink.github.io/tink_testrunner/#/basics/async-tests) in `tink_testrunner`, `tink_unittest` provides a helper class for
multiple and async assertions.


## Assertion Buffer

The other way is to use the provided `AssertionBuffer` class:

```haxe
public function test() {
	var asserts = new AssertionBuffer();
	asserts.assert(true);
	asserts.assert(true);
	return asserts.done();
}
```

### Injecting Assertion Buffer Automagically

Tag your test class with `@:asserts` and then an `AssertionBuffer` instance will be injected
into all tests methods automatically.

```haxe
@:asserts
class MyClass {
	public function test() {
		asserts.assert(true);
		return asserts.done();
	}
}
```

## Assertion Buffer

One can also use an [`AssertionBuffer`](basics/multi-assertions.md#assertion-buffer):

```haxe
public function async() {
	var asserts = new AssertionBuffer();
	var asyncTask().handle(function(o) {
		asserts.assert(o == 'async');
		asserts.done();
	});
	return asserts;
}
```

When using an `AssertionBuffer`, remember to call `done()` on it when the tests are done,
otherwise the tests will never finish and causes a [timeout](https://haxetink.github.io/tink_testrunner/#/basics/async-tests?id=timeout).


## Timeout

To set a timeout on a test, one can tag the test method with the `@:timeout` metadata:

```haxe
@:timeout(1000) // timeout in 1000 ms
public function async() {...}
```

The default timeout value is 5000ms. One can also tag the metadata at class level so that the timeout
is applied to all test methods in that class.