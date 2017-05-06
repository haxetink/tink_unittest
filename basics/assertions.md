# Assertions

## Macro solution

By using `tink.unit.Assert.assert` to create an `Assertion`, 
the description will be automatically filled by the stringified input expression.

## Basic Assertion

An assertion is described the `Assertion` class. To create an assertion:

```haxe
new Assertion(true, 'A passed assertion');
new Assertion(false, 'A failed assertion');
new Assertion(Failure('fail reason'), 'A failed assertion with reason');
```

## Multiple Assertions

A test should always return am `Assertions`, which is essentially `Stream<Assertion>`.
There are multiple implicit casts in place to ease the writing of a test.
Basically one can return a single Assertion, an array of Assertions or the Future/Promise version of them. 

