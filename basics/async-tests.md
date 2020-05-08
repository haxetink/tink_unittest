# Async Tests

`tink_unittest` provides a helper class `AssertionBuffer` for multiple and async assertions, in addition to the ways [mentioned](https://haxetink.github.io/tink_testrunner/#/basics/async-tests) in `tink_testrunner`.


## Assertion Buffer

```haxe
public function multiAsserts() {
	var asserts = new AssertionBuffer();
	asserts.assert(true);
	asserts.assert(true);
	return asserts.done();
}

public function async() {
	var asserts = new AssertionBuffer();
	var asyncTask().handle(function(o) {
		asserts.assert(o == 'async');
		asserts.done();
	});
	return asserts;
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

## Timeout

To set a timeout on a test, one can tag the test method with the `@:timeout` metadata:

```haxe
@:timeout(1000) // timeout in 1000 ms
public function async() {...}
```

The default timeout value is 5000ms. One can also tag the metadata at class level so that the timeout
is applied to all test methods in that class.