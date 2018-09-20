# Parameters

Sometimes it is useful to parameterize your tests. A common application is to test the same piece of logic with different inputs.
tink_unittest supports that using the `@:variant` metadata

## Basic usage

```haxe
@:variant(1, 1)
@:variant(3, 9)
@:variant(5, 25)
public function square(input:Int, output:Int) {
	return tink.unit.Assert.assert(input * input == output);
}
```

## Custom descriptions

By default tink_unittest will stringify the expressions inside the `@:variant` metadata and use it as the test description.
But it is also customizable. We achieve so by exploiting the function-call syntax on a string:

```haxe
@:variant("Square of 1 is 1" (1, 1))
@:variant("Square of 3 is 9" (3, 9))
@:variant("Square of 5 is 25" (5, 25))
public function square(input:Int, output:Int) {
	return tink.unit.Assert.assert(input * input == output);
}
```