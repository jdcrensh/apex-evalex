# Apex EvalEx - Apex Expression Evaluator

[![deploy to salesforce](https://img.shields.io/badge/salesforce-deploy-blue.svg)](https://githubsfdeploy.herokuapp.com)
[![Build Status](https://img.shields.io/travis/jdcrensh/apex-evalex.svg)](https://travis-ci.org/jdcrensh/apex-evalex)
[![Coverage Status](https://img.shields.io/coveralls/jdcrensh/apex-evalex.svg)](https://coveralls.io/github/jdcrensh/apex-evalex?branch=master)
[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)

### Introduction

EvalEx is a handy expression evaluator for Apex (ported from [Java EvalEx](https://github.com/uklimaschewski/EvalEx)),
that allows to evaluate simple mathematical and boolean expressions.

Key Features:
- Uses Decimal for calculation and result
- Single class implementation, very compact
- No dependencies to external libraries
- Precision and rounding mode can be set
- Supports variables
- Standard boolean and mathematical operators
- Standard basic mathematical and boolean functions
- Custom functions and operators can be added at runtime
- Functions can be defined with a variable number of arguments (see MIN and MAX functions)


### Usage Examples

```java
Decimal result = null;

RT_Expression expression = new RT_Expression('1+1/3');
result = expression.eval():
expression.setPrecision(2);
result = expression.eval():

result = new RT_Expression('(3.4 + -4.1)/2').eval();

result = new RT_Expression('SQRT(a^2 + b^2').with('a', '2.4').with('b', '9.253').eval();

Decimal a = Decimal.valueOf('2.4');
Decimal b = Decimal.valueOf('9.235');

result = new RT_Expression('SQRT(a^2 + b^2').with('a', a).with('b', b).eval();

result = new RT_Expression('2.4/PI').setPrecision(16).setRoundingMode(RoundingMode.UP).eval();

result = new RT_Expression('random() > 0.5').eval();

result = new RT_Expression('not(x<7 || sqrt(max(x,9,3,min(4,3))) <= 3))').with('x', '22.9').eval();

result = new RT_Expression('log10(100)').eval();
```

### Supported Operators

#### Mathematical Operators

<table>
  <tr><th>Operator</th><th>Description</th></tr>
  <tr><td>+</td><td>Additive operator</td></tr>
  <tr><td>-</td><td>Subtraction operator</td></tr>
  <tr><td>*</td><td>Multiplication operator</td></tr>
  <tr><td>/</td><td>Division operator</td></tr>
  <tr><td>%</td><td>Remainder operator (Modulo)</td></tr>
  <tr><td>^</td><td>Power operator</td></tr>
</table>


#### Boolean Operators

<table>
  <tr><th>Operator</th><th>Description</th></tr>
  <tr><td>=</td><td>Equals</td></tr>
  <tr><td>==</td><td>Equals</td></tr>
  <tr><td>!=</td><td>Not equals</td></tr>
  <tr><td>&lt;&gt;</td><td>Not equals</td></tr>
  <tr><td>&lt;</td><td>Less than</td></tr>
  <tr><td>&lt;=</td><td>Less than or equal to</td></tr>
  <tr><td>&gt;</td><td>Greater than</td></tr>
  <tr><td>&gt;=</td><td>Greater than or equal to</td></tr>
  <tr><td>&amp;&amp;</td><td>Boolean and</td></tr>
  <tr><td>||</td><td>Boolean or</td></tr>
</table>

\* Boolean operators result always in a Decimal value of 1 or 0 (zero). Any non-zero value is treated as a `true`
value. Boolean `not` is implemented by a function.

### Supported Functions

<table>
  <tr><th>Function<sup>*</sup></th><th>Description</th></tr>
  <tr><td>NOT(<i>expression</i>)</td><td>Boolean negation, 1 (means true) if the expression is not zero</td></tr>
  <tr><td>IF(<i>condition</i>,<i>value_if_true</i>,<i>value_if_false</i>)</td><td>Returns one value if the condition evaluates to true or the other if it evaluates to false</td></tr>
  <tr><td>RANDOM()</td><td>Produces a random number between 0 and 1</td></tr>
  <tr><td>MIN(<i>e1</i>,<i>e2</i>, <i>...</i>)</td><td>Returns the smallest of the given expressions</td></tr>
  <tr><td>MAX(<i>e1</i>,<i>e2</i>, <i>...</i>)</td><td>Returns the biggest of the given expressions</td></tr>
  <tr><td>ABS(<i>expression</i>)</td><td>Returns the absolute (non-negative) value of the expression</td></tr>
  <tr><td>ROUND(<i>expression</i>,precision)</td><td>Rounds a value to a certain number of digits, uses the current rounding mode</td></tr>
  <tr><td>FLOOR(<i>expression</i>)</td><td>Rounds the value down to the nearest integer</td></tr>
  <tr><td>CEILING(<i>expression</i>)</td><td>Rounds the value up to the nearest integer</td></tr>
  <tr><td>LOG(<i>expression</i>)</td><td>Returns the natural logarithm (base e) of an expression</td></tr>
  <tr><td>LOG10(<i>expression</i>)</td><td>Returns the common logarithm (base 10) of an expression</td></tr>
  <tr><td>SQRT(<i>expression</i>)</td><td>Returns the square root of an expression</td></tr>
  <tr><td>SIN(<i>expression</i>)</td><td>Returns the trigonometric sine of an angle (in degrees)</td></tr>
  <tr><td>COS(<i>expression</i>)</td><td>Returns the trigonometric cosine of an angle (in degrees)</td></tr>
  <tr><td>TAN(<i>expression</i>)</td><td>Returns the trigonometric tangens of an angle (in degrees)</td></tr>
  <tr><td>ASIN(<i>expression</i>)</td><td>Returns the angle of asin (in degrees)</td></tr>
  <tr><td>ACOS(<i>expression</i>)</td><td>Returns the angle of acos (in degrees)</td></tr>
  <tr><td>ATAN(<i>expression</i>)</td><td>Returns the angle of atan (in degrees)</td></tr>
  <tr><td>SINH(<i>expression</i>)</td><td>Returns the hyperbolic sine of a value</td></tr>
  <tr><td>COSH(<i>expression</i>)</td><td>Returns the hyperbolic cosine of a value</td></tr>
  <tr><td>TANH(<i>expression</i>)</td><td>Returns the hyperbolic tangens of a value</td></tr>
  <tr><td>RAD(<i>expression</i>)</td><td>Converts an angle measured in degrees to an approximately equivalent angle measured in radians</td></tr>
  <tr><td>DEG(<i>expression</i>)</td><td>Converts an angle measured in radians to an approximately equivalent angle measured in degrees</td></tr>
</table>

\* Functions names are case insensitive.

### Supported Constants

<table>
  <tr><th>Constant</th><th>Description</th></tr>
  <tr><td>PI</td><td>The value of <i>PI</i>, exact to 100 digits</td></tr>
  <tr><td>TRUE</td><td>The value one</td></tr>
  <tr><td>FALSE</td><td>The value zero</td></tr>
</table>


### Adding Custom Operators

Custom operators can be added easily, simply create an instance of `RT_Expression.Operator` and add it to the expression.
Parameters are the operator string, its precedence and if it is left associative. The operators `eval()` method will be
called with the Decimal values of the operands.

All existing operators can also be overridden.

### Add Custom Functions

Adding custom functions is as easy as adding custom operators. Create an instance of `RT_Expression.Function`and add it to
the expression. Parameters are the function name and the count of required parameters. The functions `eval()` method
will be called with a list of the Decimal parameters. A `-1` as the number of parameters denotes a variable number of
arguments.

All existing functions can also be overridden.
