# XQSuite - Annotation-based Test Framework for XQuery

## Introduction

XQSuite is a new test framework for XQuery modules based on XQuery function annotations. It has a number of advantages over previous approaches:

-   tests can be defined within the actual application code (if you like), so a function can be tested right where it is implemented. Because annotations are ignored during normal execution, they do not interfere with the application.

-   more complex integration tests can be combined into separate modules using the full power of XQuery. Tests are written as ordinary XQuery functions with all the support provided by XQuery editors like eXide.

-   properly written tests are easy to read and understand.

-   XQSuite is itself implemented in 100% XQuery and can be extended. To run a suite of tests, all you need is a small, main XQuery which imports the modules to be tested.

## Introduction

eXist-db previously used a descriptive XML format to define XQuery tests. XQSuite replaces this, though the old format and test runner is still supported and is used by many of the tests in `tests/src/xquery`.

XQSuite has two components:

-   A number of XQuery function annotations to be used within the code module to be tested

-   A test runner which takes a sequence of function items and interprets the test annotations

To use test annotations in a given XQuery module, the corresponding namespace has to be declared:

declare namespace test="http://exist-db.org/xquery/xqsuite";
A function in the module will be considered by the test runner if it has at least one `test:assertXXX` annotation, where "XXX" stands for the annotation type ("assertEquals", "assertEmpty" ...). Other functions - including private ones - will be simply ignored. A minimal example may thus look as follows:

``` xquery
declare %test:assertEquals("Hello world") function local:hello() {
    "Hello world"
};
```

When the test runner encounters this function, it will evaluate it once and compare its return value to the assertion.

## Parameterized Tests

The simple example above does not expect any parameters. To test a function which does take parameters, use the `%test:arg` annotation in combination with one or more assertions:

``` xquery
declare
    %test:arg("n", 1) %test:assertEquals(1)
    %test:arg("n", 5) %test:assertEquals(120)
function m:factorial($n as xs:int) as xs:int {
    if ($n = 1) then
        1
    else
        $n * m:factorial($n - 1)
};
```

This example shows multiple tests on the same function using different parameter values. The `%test:arg` annotation is used to set the parameters for the next test run, which is triggered by the assertion. This means the tested function will be called once for every sequence of `%test:arg` annotations followed by one or more `%test:assertXXX`. The order of the annotations is thus important!

The first annotation argument to `%test:arg` denotes the name of the function parameter variable to set, the remaining arguments are used to create the sequence of values passed. There have to be as many %test:arg annotations for every test run as the function takes parameters.

The result returned by the function call is passed to each assertion in turn, which may either pass or fail. In the example above, we assert that the function should return 1 if the input parameter is 1, and 120 if the input is 5.

To test a function which takes a sequence with more than one item for a parameter, just append additional values to `%test:arg`. The test runner will convert the values into a sequence.

If all function parameters expect exactly one value, you can also use a shorter form of `%test:arg`: instead of specifying one `%test:arg` annotation for every parameter, use a single `%test:args` annotation to define all parameter values at once. `%test:args` simply takes a list of values. Each value is mapped to exactly one function parameter. Example:

``` xquery
declare
    %test:args("Hello", "world")
    %test:assertEquals("Hello world")
function local:hello($greet as xs:string, $user as xs:string) {
    $greet || " " || $user
};
```

## Automatic Type Conversion

XQuery annotation parameters need to be literal values, so only strings and numbers are allowed. XQSuite thus applies type conversion to every argument as well as to values used in assertions. For example, the following function expects a parameter of type `xs:date`:

``` xquery
declare
    %test:args("2012-06-26")
    %test:assertEquals("26.6.2012")
    %test:args("2012-06-01")
    %test:assertEquals("1.6.2012")
function fd:simple-date($date as xs:date) as xs:string {
    format-date($date, "[D].[M].[Y]")
};
```

The string value passed to the `%test:args` annotation is automatically converted to the sequence type declared for the function parameter: `xs:date`. The same applies to the assertion values.

Type conversion works for all primitive types as well as XML nodes.

If automatic type conversion fails for some reason, the test case will fail as well.

## Supported Annotations

%test:arg($varName, $value1, $value2, ...)  
Set the function parameter with variable name $varName to the sequence constructed by converting the remaining annotation parameters to the sequenceType declared by the function parameter.

%test:args($arg1, $arg2, ...)  
Run the function using the supplied literal arguments. There has to be one annotation argument for each parameter the function takes.

%test:assertEmpty, %test:assertExists  
Expects the function to return an empty sequence (assertEmpty) or a non-empty sequence (assertExists).

%test:assertTrue, %test:assertFalse  
Checks if the effective boolean value of the returned result is true or false.

%test:assertEquals($value1, $value2, ...)  
Tests if the return value equals the specified argument. If the function returns more than one item, each item is compared to the given annotation values in turn. The number of returned items has to correspond to the number of annotation values.  If the function returns an atomic type, the assertion argument is cast into the same type and the two are compared using the eq operator.  If the sequence returned by the function contains one or more XML elements, they will be normalized (i.e. ignorable whitespace is stripped). The assertion argument is then parsed into XML and the two node trees are compared using the deep-equals function.

%test:assertError($errString)  
Evaluating the tested function should result in a dynamic error. If value is given, it should either be a string contained in the error description or correspond to the error code of the dynamic error.

The annotation value is executed as an XPath expression. The assert passes if the XPath expression returns a non-empty sequence or a single atomic item whose effective boolean value is true. Within the XPath expression, the variable **$result**contains a reference to the result sequence returned by the tested function.

%test:pending  
Marks a test as *pending*, which means that it will not be executed as part of the test suite. This can be useful when you want to write a test for a problem or new feature but you have not had time to fix the problem of implement the feature. The count of *pending* tests is shown in the test suite report to remind you of tests that are present but not yet executed.

%test:setUp, %test:tearDown  
Special functions which will be called once before (or after) any other tests contained in the same XQuery module are run. Use those functions to upload data, create indexes, users or prepare anything else needed for tests to run.

## Running a Test Suite

To run a suite of tests, you need to create a main XQuery which

1.  imports the `xqsuite.xql` test framework

2.  calls `test:suite` with the sequence of function items to test

For a complete example, store the following XQuery module into the database as `math.xql`:

``` xquery
xquery version "3.0";

module namespace m="http://foo.org/xquery/math";

declare namespace test="http://exist-db.org/xquery/xqsuite";

declare
    %test:arg("n", 1) %test:assertEquals(1)
    %test:arg("n", 5) %test:assertEquals(120)
function m:factorial($n as xs:int) as xs:int {
    if ($n = 1) then
        1
    else
        $n * m:factorial($n - 1)
};
```

To run the tests in this module, create a main XQuery called `suite.xql` and store it into the same collection:

``` xquery
xquery version "3.0";

import module namespace test="http://exist-db.org/xquery/xqsuite" 
at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

test:suite(
    inspect:module-functions(xs:anyURI("math.xql"))
)
```

Executing the main XQuery within eXide will return the test results as an XML fragment (see below).

In the main XQuery, the function: `inspect:module-functions` returns a function item for every public function defined in the module loaded from the location URI given as argument. The location URI is resolved in the same way as in a normal module import, so a relative path will be interpreted relative to the location of the main XQuery.

## Test Suite Output

`test:suite` returns the results of the tests as an XML fragment using the schema defined by the xUnit test tool. The xUnit format is supported by many systems, e.g. Jenkins, and is thus a good choice, even though it was designed for Java and not XQuery. For every XQuery module tested, `test:suite` creates one testsuite element. The result of each test run is output as a testcase element. It will be empty if the test has passed. If the test failed, there will be a failure element containing the expected result of the function, and an output element with the actual result. An example is given below:

``` xml
<testsuites>
    <testsuite package="http://exist-db.org/xquery/test/bang" timestamp="2012-10-16T10:30:12.966+02:00" failures="1" tests="19" time="PT0.046S">
        <testcase name="constructor" class="bang:constructor"/>
        <testcase name="functions1" class="bang:functions1"/>
        <testcase name="functions2" class="bang:functions2"/>
        <testcase name="functions3" class="bang:functions3">
            <failure message="assertEquals failed." type="failure-error-code-1">RED BLACK GREEN</failure>
            <output>RED BLUE GREEN</output>
        </testcase>
        <testcase name="functions4" class="bang:functions4"/>
        <testcase name="nodepath" class="bang:nodepath"/>
        <testcase name="nodepath-reverse" class="bang:nodepath-reverse"/>
        <testcase name="nodes1" class="bang:nodes1"/>
        <testcase name="nodes2" class="bang:nodes2"/>
        <testcase name="numbers1" class="bang:numbers1"/>
        <testcase name="position1" class="bang:position1"/>
        <testcase name="position2" class="bang:position2"/>
        <testcase name="position3" class="bang:position3"/>
        <testcase name="position4" class="bang:position4"/>
        <testcase name="position5" class="bang:position5"/>
        <testcase name="precedence1" class="bang:precedence1"/>
        <testcase name="precedence2" class="bang:precedence2"/>
        <testcase name="precedence3" class="bang:precedence3"/>
        <testcase name="sequence" class="bang:sequence"/>
    </testsuite>
</testsuites>
```
