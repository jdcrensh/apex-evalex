@isTest class RT_ExpressionTest {

	/* Booleans
	 */
	
	@isTest static void testAndTokenizer() {
		RT_Expression e = new RT_Expression('1&&0');
		Iterator<RT_Expression.Token> it = e.getExpressionTokenizer();
		System.assertEquals('1', it.next().text);
		System.assertEquals('&&', it.next().text);
		System.assertEquals('0', it.next().text);
	}
	
	@isTest static void testAndRPN() {
		System.assertEquals('1 0 &&', new RT_Expression('1&&0').toRPN());
	}
	
	@isTest static void testAndEval() {
		System.assertEquals(false, new RT_Expression('1&&0').evalBool());
		System.assertEquals(true, new RT_Expression('1&&1').evalBool());
		System.assertEquals(false, new RT_Expression('0&&0').evalBool());
		System.assertEquals(false, new RT_Expression('0&&1').evalBool());
	}
	
	@isTest static void testOrEval() {
		System.assertEquals('1', new RT_Expression('1||0').eval() + '');
		System.assertEquals('1', new RT_Expression('1||1').eval() + '');
		System.assertEquals('0', new RT_Expression('0||0').eval() + '');
		System.assertEquals('1', new RT_Expression('0||1').eval() + '');
	}
	
	@isTest static void testCompare() {
		System.assertEquals('1', new RT_Expression('2>1').eval() + '');
		System.assertEquals('0', new RT_Expression('2<1').eval() + '');
		System.assertEquals('0', new RT_Expression('1>2').eval() + '');
		System.assertEquals('1', new RT_Expression('1<2').eval() + '');
		System.assertEquals('0', new RT_Expression('1=2').eval() + '');
		System.assertEquals('1', new RT_Expression('1=1').eval() + '');
		System.assertEquals('1', new RT_Expression('1>=1').eval() + '');
		System.assertEquals('1', new RT_Expression('1.1>=1').eval() + '');
		System.assertEquals('0', new RT_Expression('1>=2').eval() + '');
		System.assertEquals('1', new RT_Expression('1<=1').eval() + '');
		System.assertEquals('0', new RT_Expression('1.1<=1').eval() + '');
		System.assertEquals('1', new RT_Expression('1<=2').eval() + '');
		System.assertEquals('0', new RT_Expression('1=2').eval() + '');
		System.assertEquals('1', new RT_Expression('1=1').eval() + '');
		System.assertEquals('1', new RT_Expression('1!=2').eval() + '');
		System.assertEquals('0', new RT_Expression('1!=1').eval() + '');
	}
	
	@isTest static void testCompareCombined() {
		System.assertEquals('1', new RT_Expression('(2>1)||(1=0)').eval() + '');
		System.assertEquals('0', new RT_Expression('(2>3)||(1=0)').eval() + '');
		System.assertEquals('1', new RT_Expression('(2>3)||(1=0)||(1&&1)').eval() + '');
	}
	
	@isTest static void testMixed() {
		System.assertEquals('0', new RT_Expression('1.5 * 7 = 3').eval() + '');
		System.assertEquals('1', new RT_Expression('1.5 * 7 = 10.5').eval() + '');
	}
	
	@isTest static void testNot() {
		System.assertEquals('0', new RT_Expression('not(1)').eval() + '');
		System.assertEquals('1', new RT_Expression('not(0)').eval() + '');
		System.assertEquals('1', new RT_Expression('not(1.5 * 7 = 3)').eval() + '');
		System.assertEquals('0', new RT_Expression('not(1.5 * 7 = 10.5)').eval() + '');
	}
	
	@isTest static void testConstants() {
		System.assertEquals(true, new RT_Expression('TRUE!=FALSE').evalBool());
		System.assertEquals(false, new RT_Expression('TRUE==2').evalBool());
		System.assertEquals(true, new RT_Expression('NOT(TRUE)==FALSE').evalBool());
		System.assertEquals(true, new RT_Expression('NOT(FALSE)==TRUE').evalBool());
		System.assertEquals(false, new RT_Expression('TRUE && FALSE').evalBool());
		System.assertEquals(true, new RT_Expression('TRUE || FALSE').evalBool());
	}
	
	@isTest static void testIf() {
		System.assertEquals('5', new RT_Expression('if(TRUE, 5, 3)').eval() + '');
		System.assertEquals('3', new RT_Expression('IF(FALSE, 5, 3)').eval() + '');
		System.assertEquals('5.35', new RT_Expression('If(2, 5.35, 3)').eval() + '');
	}
	
	/* Strings
	 */
	
	@isTest static void testStringCompare() {
		System.assertEquals(true, new RT_Expression('"foo" == "foo"').evalBool());
		System.assertEquals(false, new RT_Expression('"foo" == "bar"').evalBool());
		System.assertEquals(true, new RT_Expression('"foo" != "bar"').evalBool());
		System.assertEquals(true, new RT_Expression('"foo" <> "bar"').evalBool());
		System.assertEquals(true, new RT_Expression('"foo" > \'bar\'').evalBool());
		System.assertEquals(true, new RT_Expression('"foo" >= "bar"').evalBool());
		System.assertEquals(false, new RT_Expression('"foo" < "bar"').evalBool());
		System.assertEquals(false, new RT_Expression('"foo" <= "bar"').evalBool());
	}
	
	@isTest static void testStringConcat() {
		System.assertEquals(true, new RT_Expression('"foo" + "bar" == "foobar"').evalBool());
		System.assertEquals(true, new RT_Expression('"foo" + 1 == \'foo1\'').evalBool());
		System.assertEquals(true, new RT_Expression('1+"foo" == \'1foo\'').evalBool());
		System.assertEquals(false, new RT_Expression('1+"foo" != \'1foo\'').evalBool());
		System.assertEquals(true, new RT_Expression('2+1+"foo" = \'3foo\'').evalBool());
	}
	
	@isTest static void testStringMixed() {
		System.assertEquals(3, new RT_Expression('1+(IF("foo" != "bar", 1, 0)*2)').eval());
	}
	
	/* Case Insensitive
	 */
	
	@isTest static void testVariableIsCaseInsensitive() {
	
		RT_Expression expression = new RT_Expression('a');
		expression.setVariable('A', 20);
		System.assertEquals(expression.eval().intValue(), 20);
		
		expression = new RT_Expression('a + B');
		expression.setVariable('A', 10);
		expression.setVariable('b', 10);
		System.assertEquals(expression.eval().intValue(), 20);
		
		expression = new RT_Expression('a+B');
		expression.setVariable('A', 10);
		expression.setVariable('b', 10);
		expression.setVariable('C', 5);
		expression.setVariable('d', 5);
		System.assertEquals(expression.eval().intValue(), 20);
	}
	
	@isTest static void testFunctionCaseInsensitive() {
		RT_Expression expression = new RT_Expression('a+testsum(1,3)');
		expression.setVariable('A', 1);
		RT_Expression.addFunction(new SumFunction('testSum', -1));
		System.assertEquals(expression.eval(), 5);
	}
	
	public class SumFunction extends RT_Expression.Function {
		public SumFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, RT_Expression.MathContext mc) {
			Decimal value = null;
			for (Object parameter : parameters) {
				Decimal d = (Decimal) parameter;
				value = value == null ? d : value + d;
			}
			return value;
		}
	}
	
	/* Customs
	 */
	
	class BitRightOperator extends RT_Expression.Operator {
		public BitRightOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, RT_Expression.MathContext mc) {
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return d1.longValue() >> d2.longValue();
		}
	}
	
	@isTest static void testCustomOperator() {
		RT_Expression e = new RT_Expression('132 >> 7');
		RT_Expression.addOperator(new BitRightOperator('>>', 30, RT_Expression.Associability.LEFT));
		System.assertEquals('1', e.eval().toPlainString());
	}
	
	class AvgFunction extends RT_Expression.Function {
		public AvgFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, RT_Expression.MathContext mc) {
			if (numParams > -1 && numParams != parameters.size()) {
				throw new RT_Expression.ExpressionException('AVG function requires ' + numParams + ' parameters');
			}
			Decimal avg = 0;
			for (Object parameter : parameters) {
				avg += (Decimal) parameter;
			}
			return avg.divide(Decimal.valueOf(parameters.size()), mc.precision, mc.roundingMode);
		}
	}
	
	@isTest static void testCustomFunction() {
		RT_Expression e = new RT_Expression('2 * average(12,4,8)');
		RT_Expression.addFunction(new AvgFunction('average', 3));
		System.assertEquals('16', e.eval().toPlainString());
	}
	
	@isTest static void testCustomFunctionVariableParameters() {
		RT_Expression e = new RT_Expression('2 * average(12,4,8,2,9)');
		RT_Expression.addFunction(new AvgFunction('average', -1));
		System.assertEquals('14', e.eval().toPlainString());
	}
	
	/* Eval
	 */
	
	@isTest static void testUnary() {
		System.assertEquals(2, new RT_Expression('-3+5').eval());
		System.assertEquals(-30, new RT_Expression('-5+(-25)').eval());
		System.assertEquals(125, new RT_Expression('-5*(-25)').eval());
		System.assertEquals(-1, new RT_Expression('0-x').with('x', 1).eval());
	}
	
	@isTest static void testInvalidExpressions1() {
		String err = '';
		try {
			RT_Expression expression = new RT_Expression('12 18 2');
			expression.eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		
		System.assertEquals('Too many numbers or variables', err);
	}
	
	@isTest static void testInvalidExpressions2() {
		String err;
		try {
			RT_Expression expression = new RT_Expression('(12)(18)');
			expression.eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		
		System.assertEquals('Too many numbers or variables', err);
	}
	
	@isTest static void testInvalidExpressions3() {
		String err;
		try {
			RT_Expression expression = new RT_Expression('12 + * 18');
			expression.eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		
		System.assertEquals('Too many operators or functions at: +', err);
	}
	
	@isTest static void testInvalidExpressions4() {
		String err;
		try {
			RT_Expression expression = new RT_Expression('');
			expression.eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		
		System.assertEquals('Empty expression', err);
	}
	
	@isTest static void testInvalidExpressions5() {
		RT_Expression expression = new RT_Expression('');
		System.assert(expression.evalBool());
	}
	
	@isTest static void testWrongBrackets1() {
		String err;
		try {
			RT_Expression expression = new RT_Expression('2*3(5*3)');
			expression.eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		System.assertEquals('Missing operator at character position 4', err);
	}
	
	@isTest static void testWrongBrackets2() {
		String err;
		try {
			new RT_Expression('2*(3((5*3)))').eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		System.assertEquals('Missing operator at character position 5', err);
	}
	
	@isTest static void testInvalidString() {
		String err;
		try {
			new RT_Expression('"foo" = "foo').eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		System.assertEquals('Parse error of string at position 9', err);
	}
	
	@isTest static void testBrackets() {
		System.assertEquals('3', new RT_Expression('(1+2)').eval().toPlainString());
		System.assertEquals('3', new RT_Expression('((1+2))').eval().toPlainString());
		System.assertEquals('3', new RT_Expression('(((1+2)))').eval().toPlainString());
		System.assertEquals('9', new RT_Expression('(1+2)*(1+2)').eval().toPlainString());
		System.assertEquals('10', new RT_Expression('(1+2)*(1+2)+1').eval().toPlainString());
		System.assertEquals('12', new RT_Expression('(1+2)*((1+2)+1)').eval().toPlainString());
	}
	
	@isTest static void testUnknown1() {
		try {
			new RT_Expression('7#9').eval().toPlainString();
			System.assert(false);
		}
		catch (RT_Expression.ExpressionException expected) {}
	}
	
	@isTest static void testUnknown2() {
		try {
			new RT_Expression('123.6*-9.8-7#9').eval().toPlainString();
			System.assert(false);
		}
		catch (RT_Expression.ExpressionException expected) {}
	}
	
	@isTest static void testSimple() {
		System.assertEquals('3', new RT_Expression('1+2').eval().toPlainString());
		System.assertEquals('2', new RT_Expression('4/2').eval().toPlainString());
		System.assertEquals('5', new RT_Expression('3+4/2').eval().toPlainString());
		System.assertEquals('3.5', new RT_Expression('(3+4)/2').eval().toPlainString());
		System.assertEquals('7.98', new RT_Expression('4.2*1.9').eval().toPlainString());
		System.assertEquals('2', new RT_Expression('8%3').eval().toPlainString());
		System.assertEquals('0', new RT_Expression('8%2').eval().toPlainString());
	}
	
	@isTest static void testPow() {
		System.assertEquals('16', new RT_Expression('2^4').eval().toPlainString());
		System.assertEquals('256', new RT_Expression('2^8').eval().toPlainString());
		System.assertEquals('9', new RT_Expression('3^2').eval().toPlainString());
		System.assertEquals('6.25', new RT_Expression('2.5^2').eval().toPlainString());
		System.assertEquals('28.34045', new RT_Expression('2.6^3.5').eval().toPlainString());
	}
	
	@isTest static void testSqrt() {
		System.assertEquals('4', new RT_Expression('SQRT(16)').eval().toPlainString());
		System.assertEquals('1.414214', new RT_Expression('SQRT(2)').eval().toPlainString());
		System.assertEquals('1.4142135623730951', new RT_Expression('SQRT(2)').setPrecision(17).eval().toPlainString());
		System.assertEquals('2.236068', new RT_Expression('SQRT(5)').eval().toPlainString());
		System.assertEquals('99.37303', new RT_Expression('SQRT(9875)').eval().toPlainString());
		System.assertEquals('2.355844', new RT_Expression('SQRT(5.55)').eval().toPlainString());
		System.assertEquals('0.0', new RT_Expression('SQRT(0)').eval().toPlainString());
	}
	
	@isTest static void testFunctions() {
		System.assertNotEquals('1.5', new RT_Expression('Random()').eval().toPlainString());
		System.assertEquals('0.400349', new RT_Expression('SIN(23.6)').eval().toPlainString());
		System.assertEquals('8', new RT_Expression('MAX(-7,8)').eval().toPlainString());
		System.assertEquals('5', new RT_Expression('MAX(3,max(4,5))').eval().toPlainString());
		System.assertEquals('9.6', new RT_Expression('MAX(3,max(MAX(9.6,-4.2),Min(5,9)))').eval().toPlainString());
		System.assertEquals('2.302585', new RT_Expression('LOG(10)').eval().toPlainString());
	}
	
	@isTest static void testExpectedParameterNumbers() {
		String err;
		try {
			RT_Expression expression = new RT_Expression('Random(1)');
			expression.eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		System.assertEquals('Function RANDOM expected 0 parameters, got 1', err);
		
		try {
			RT_Expression expression = new RT_Expression('SIN(1, 6)');
			expression.eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		System.assertEquals('Function SIN expected 1 parameters, got 2', err);
	}
	
	@isTest static void testVariableParameterNumbers() {
		String err;
		try {
			RT_Expression expression = new RT_Expression('min()');
			expression.eval();
		}
		catch (RT_Expression.ExpressionException e) {
			err = e.getMessage();
		}
		System.assertEquals('Function MIN expected -1 parameters, got 0', err);
		
		System.assertEquals('1', new RT_Expression('min(1)').eval().toPlainString());
		System.assertEquals('1', new RT_Expression('min(1, 2)').eval().toPlainString());
		System.assertEquals('1', new RT_Expression('min(1, 2, 3)').eval().toPlainString());
		System.assertEquals('3', new RT_Expression('max(3, 2, 1)').eval().toPlainString());
		System.assertEquals('9', new RT_Expression('max(3, 2, 1, 4, 5, 6, 7, 8, 9, 0)').eval().toPlainString());
	}
	
	@isTest static void testExtremeFunctionNesting() {
		System.assertNotEquals('1.5', new RT_Expression('Random()').eval().toPlainString());
		System.assertEquals('0.0002791281', new RT_Expression('SIN(SIN(COS(23.6)))').eval().toPlainString());
		System.assertEquals('-4', new RT_Expression('MIN(0, SIN(SIN(COS(23.6))), 0-MAX(3,4,MAX(0,SIN(1))), 10)').eval().toPlainString());
	}
	
	@isTest static void testTrigonometry() {
		System.assertEquals('0.5', new RT_Expression('SIN(30)').eval().toPlainString());
		System.assertEquals('0.8660254', new RT_Expression('cos(30)').eval().toPlainString());
		System.assertEquals('0.5773503', new RT_Expression('TAN(30)').eval().toPlainString());
		System.assertEquals('5343237000000', new RT_Expression('SINH(30)').eval().toPlainString());
		System.assertEquals('5343237000000', new RT_Expression('COSH(30)').eval().toPlainString());
		System.assertEquals('1', new RT_Expression('TANH(30)').eval().toPlainString());
		System.assertEquals('0.5235988', new RT_Expression('RAD(30)').eval().toPlainString());
		System.assertEquals('1718.873', new RT_Expression('DEG(30)').eval().toPlainString());
	}
	
	@isTest static void testAsin() {
		System.assertEquals('0', new RT_Expression('ASIN(0)').eval().toPlainString());
		System.assertEquals('90', new RT_Expression('ASIN(1)').eval().toPlainString());
		System.assertEquals('5.73917', new RT_Expression('ASIN(0.1)').eval().toPlainString());
		System.assertEquals('30', new RT_Expression('ASIN(0.5)').eval().toPlainString());
	}
	
	@isTest static void testAcos() {
		System.assertEquals('90', new RT_Expression('ACOS(0)').eval().toPlainString());
		System.assertEquals('0', new RT_Expression('ACOS(1)').eval().toPlainString());
		System.assertEquals('84.26083', new RT_Expression('ACOS(0.1)').eval().toPlainString());
		System.assertEquals('60', new RT_Expression('ACOS(0.5)').eval().toPlainString());
	}
	
	@isTest static void testAtan() {
		System.assertEquals('0', new RT_Expression('ATAN(0)').eval().toPlainString());
		System.assertEquals('45', new RT_Expression('ATAN(1)').eval().toPlainString());
		System.assertEquals('5.710593', new RT_Expression('ATAN(0.1)').eval().toPlainString());
		System.assertEquals('26.56505', new RT_Expression('ATAN(0.5)').eval().toPlainString());
	}
	
	@isTest static void testLog10() {
		System.assertEquals('0.0', new RT_Expression('LOG10(1)').eval().toPlainString());
		System.assertEquals('1', new RT_Expression('LOG10(10)').eval().toPlainString());
		System.assertEquals('2', new RT_Expression('LOG10(100)').eval().toPlainString());
		System.assertEquals('1.69897', new RT_Expression('LOG10(50)').eval().toPlainString());
	}
	
	@isTest static void testMinMaxAbs() {
		System.assertEquals('3.78787', new RT_Expression('MAX(3.78787,3.78786)').eval().toPlainString());
		System.assertEquals('3.78787', new RT_Expression('max(3.78786,3.78787)').eval().toPlainString());
		System.assertEquals('3.78786', new RT_Expression('MIN(3.78787,3.78786)').eval().toPlainString());
		System.assertEquals('3.78786', new RT_Expression('Min(3.78786,3.78787)').eval().toPlainString());
		System.assertEquals('2.123', new RT_Expression('aBs(-2.123)').eval().toPlainString());
		System.assertEquals('2.123', new RT_Expression('abs(2.123)').eval().toPlainString());
	}
	
	@isTest static void testRounding() {
		System.assertEquals('3.8', new RT_Expression('round(3.78787,1)').eval().toPlainString());
		System.assertEquals('3.788', new RT_Expression('round(3.78787,3)').eval().toPlainString());
		System.assertEquals('3.734', new RT_Expression('round(3.7345,3)').eval().toPlainString());
		System.assertEquals('-3.734', new RT_Expression('round(-3.7345,3)').eval().toPlainString());
		System.assertEquals('-3.79', new RT_Expression('round(-3.78787,2)').eval().toPlainString());
		System.assertEquals('123.79', new RT_Expression('round(123.78787,2)').eval().toPlainString());
		System.assertEquals('12345678901234567.123456789012346', new RT_Expression('round(12345678901234567.1234567890123456,15)').setPrecision(33).eval().toPlainString());
		System.assertEquals('12345678901234567', new RT_Expression('round(12345678901234567.1234567890123456,0)').setPrecision(33).eval().toPlainString());
		System.assertEquals('3', new RT_Expression('floor(3.78787)').eval().toPlainString());
		System.assertEquals('4', new RT_Expression('ceiling(3.78787)').eval().toPlainString());
		System.assertEquals('-3', new RT_Expression('floor(-2.1)').eval().toPlainString());
		System.assertEquals('-2', new RT_Expression('ceiling(-2.1)').eval().toPlainString());
	}
	
	@isTest static void testMathContext() {
		RT_Expression e = null;
		e = new RT_Expression('2.5/3').setPrecision(2);
		System.assertEquals('0.83', e.eval().toPlainString());
		
		e = new RT_Expression('2.5/3').setPrecision(3);
		System.assertEquals('0.833', e.eval().toPlainString());
		
		e = new RT_Expression('2.5/3').setPrecision(8);
		System.assertEquals('0.83333333', e.eval().toPlainString());
		
		e = new RT_Expression('2.5/3').setRoundingMode(RoundingMode.DOWN);
		System.assertEquals('0.8333333', e.eval().toPlainString());
		
		e = new RT_Expression('2.5/3').setRoundingMode(RoundingMode.UP);
		System.assertEquals('0.8333334', e.eval().toPlainString());
	}
	
	@isTest static void testIsNumber() {
		System.assertEquals(false, RT_Expression.isNumber(''));
		System.assertEquals(false, RT_Expression.isNumber('-'));
		System.assertEquals(false, RT_Expression.isNumber('+'));
		System.assertEquals(false, RT_Expression.isNumber('e'));
		System.assertEquals(false, RT_Expression.isNumber(null));
		System.assertEquals(true, RT_Expression.isNumber('-1'));
		System.assertEquals(true, RT_Expression.isNumber('-10.5'));
		System.assertEquals(true, RT_Expression.isNumber('42.24'));
	}
	
	/* Exposed Components
	 */
	
	class NullOperator extends RT_Expression.Operator {
		public NullOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, RT_Expression.MathContext mc) {
			return null;
		}
	}
	
	@isTest static void testDeclaredOperators() {
		RT_Expression expression = new RT_Expression('c+d');
		Integer originalOperator = expression.getDeclaredOperators().size();
		RT_Expression.addOperator(new NullOperator('$$', -1, RT_Expression.Associability.LEFT));
		
		System.assert(expression.getDeclaredOperators().contains('$$'), 'Operator List should have the new $$ operator');
		System.assertEquals(expression.getDeclaredOperators().size(), originalOperator + 1, 'Should have an extra operators');
	}
	
	@isTest static void testDeclaredVariables() {
		RT_Expression expression = new RT_Expression('c+d');
		Integer originalVarCounts = expression.getDeclaredVariables().size();
		expression.setVariable('var1', 12);
		
		System.assert(expression.getDeclaredVariables().contains('VAR1'), 'Variable list should have new var1 variable declared');
		System.assertEquals(expression.getDeclaredVariables().size(), originalVarCounts + 1, 'Variable list should have q more declared variable');
	}
	
	class NullFunction extends RT_Expression.Function {
		public NullFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, RT_Expression.MathContext mc) {
			return null;
		}
	}
	
	@isTest static void testDeclaredFunctionGetter() {
		RT_Expression expression = new RT_Expression('a+b');
		Integer originalFunctionCount = expression.getDeclaredFunctions().size();
		RT_Expression.addFunction(new NullFunction('func1', 3));
		
		System.assert(expression.getDeclaredFunctions().contains('FUNC1'), 'Function list should have new func1 function declared');
		System.assertEquals(expression.getDeclaredFunctions().size(), originalFunctionCount + 1, 'Function list should have one more function declared');
	}
	
	/* Nested
	 */
	
	// nested expressions are broken in favor of String support
	static void testNestedVars() {
		String x = '1';
		String y = '2';
		String z = '2*x + 3*y';
		String a = '2*x + 4*z';
		
		RT_Expression e = new RT_Expression(a);
		e.with('x', x);
		e.with('y', y);
		e.with('z', z);
		
		System.assertEquals(34, e.eval());
	}
	
	// nested expressions are broken in favor of String support
	static void testReplacements() {
		RT_Expression e = new RT_Expression('3+a+aa+aaa').with('a', '1*x').with('aa', '2*x').with('aaa', '3*x').with('x', '2');
		System.assertEquals(15, e.eval());
	}
	
	/* RPN
	 */
	
	@isTest static void testRPNSimple() {
		System.assertEquals('1 2 +', new RT_Expression('1+2').toRPN());
		System.assertEquals('1 2 4 / +', new RT_Expression('1+2/4').toRPN());
		System.assertEquals('1 2 + 4 /', new RT_Expression('(1+2)/4').toRPN());
		System.assertEquals('1.9 2.8 + 4.7 /', new RT_Expression('(1.9+2.8)/4.7').toRPN());
		System.assertEquals('1.98 2.87 + 4.76 /', new RT_Expression('(1.98+2.87)/4.76').toRPN());
		System.assertEquals('3 4 2 * 1 5 - 2 3 ^ ^ / +', new RT_Expression('3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3').toRPN());
	}
	
	@isTest static void testRPNFunctions() {
		System.assertEquals('( 23.6 SIN', new RT_Expression('SIN(23.6)').toRPN());
		System.assertEquals('( -7 8 MAX', new RT_Expression('MAX(-7,8)').toRPN());
		System.assertEquals('( ( 3.7 SIN ( 2.6 -8.0 MAX MAX', new RT_Expression('MAX(SIN(3.7),MAX(2.6,-8.0))').toRPN());
	}
	
	
	/* Scientific Notation
	 */
	
	@isTest static void testSciSimple() {
		RT_Expression e = new RT_Expression('1e10');
		System.assertEquals('10000000000', e.eval().toPlainString());
		
		e = new RT_Expression('1E10');
		System.assertEquals('10000000000', e.eval().toPlainString());
		
		e = new RT_Expression('123.456E3');
		System.assertEquals('123456', e.eval().toPlainString());
		
		e = new RT_Expression('2.5e0');
		System.assertEquals('2.5', e.eval().toPlainString());
	}
	
	@isTest static void testSciNegative() {
		RT_Expression e = new RT_Expression('1e-10');
		System.assertEquals('0.0000000001', e.eval().toPlainString());
		
		e = new RT_Expression('1E-10');
		System.assertEquals('0.0000000001', e.eval().toPlainString());
		
		e = new RT_Expression('2135E-4');
		System.assertEquals('0.2135', e.eval().toPlainString());
	}
	
	//@Ignore('Expected Failures: not implemented yet')
	@isTest static void testSciPositive() {
		RT_Expression e = new RT_Expression('1e+10');
		System.assertEquals('10000000000', e.eval().toPlainString());
		
		e = new RT_Expression('1E+10');
		System.assertEquals('10000000000', e.eval().toPlainString());
	}
	
	@isTest static void testSciCombined() {
		RT_Expression e = new RT_Expression('sqrt(152.399025e6)', new RT_Expression.MathContext(16, RoundingMode.HALF_EVEN));
		System.assertEquals('12345', e.eval().toPlainString());
		
		e = new RT_Expression('sin(3.e1)');
		System.assertEquals('0.5', e.eval().toPlainString());
		
		e = new RT_Expression('sin( 3.e1)');
		System.assertEquals('0.5', e.eval().toPlainString());
		
		e = new RT_Expression('sin(3.e1 )');
		System.assertEquals('0.5', e.eval().toPlainString());
		
		e = new RT_Expression('sin( 3.e1 )');
		System.assertEquals('0.5', e.eval().toPlainString());
		
		e = new RT_Expression('2.2e-16 * 10.2');
		System.assertEquals('2.244E-15', e.eval() + '');
	}
	
	@isTest static void testSciError1() {
		RT_Expression e = new RT_Expression('1234e-2.3');
		try {
			e.eval();
			System.assert(false);
		}
		catch (TypeException expected) {}
	}
	
	@isTest static void testSciError2() {
		RT_Expression e = new RT_Expression('1234e2.3');
		try {
			e.eval();
			System.assert(false);
		}
		catch (TypeException expected) {}
	}
	
	@isTest static void testSciError3() {
		String err;
		RT_Expression e = new RT_Expression('e2');
		try {
			e.eval();
		}
		catch (RT_Expression.ExpressionException ex) {
			err = ex.getMessage();
		}
		System.assertEquals('Unknown function or variable \'e2\' at position 1', err);
	}
	
	/* Tokenizer
	 */
	
	@isTest static void testTokenizerNumbers() {
		RT_Expression e;
		Iterator<RT_Expression.Token> i;
		
		e = new RT_Expression('1');
		i = e.getExpressionTokenizer();
		System.assertEquals('1', i.next().text);
		System.assertEquals(false, i.hasNext());
		
		e = new RT_Expression('-1');
		i = e.getExpressionTokenizer();
		System.assertEquals('-1', i.next().text);
		System.assertEquals(false, i.hasNext());
		
		e = new RT_Expression('123');
		i = e.getExpressionTokenizer();
		System.assertEquals('123', i.next().text);
		System.assertEquals(false, i.hasNext());
		
		e = new RT_Expression('-123');
		i = e.getExpressionTokenizer();
		System.assertEquals('-123', i.next().text);
		System.assertEquals(false, i.hasNext());
		
		e = new RT_Expression('123.4');
		i = e.getExpressionTokenizer();
		System.assertEquals('123.4', i.next().text);
		System.assertEquals(false, i.hasNext());
		
		e = new RT_Expression('-123.456');
		i = e.getExpressionTokenizer();
		System.assertEquals('-123.456', i.next().text);
		System.assertEquals(false, i.hasNext());
	}
	
	@isTest static void testTokenizerExtraSpaces() {
		RT_Expression e = new RT_Expression('1 ');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		System.assert(i.hasNext());
		System.assertEquals('1', i.next().text);
		System.assertEquals(false, i.hasNext());
		
		e = new RT_Expression('       ');
		i = e.getExpressionTokenizer();
		System.assertEquals(false, i.hasNext());
		
		e = new RT_Expression('   1      ');
		i = e.getExpressionTokenizer();
		System.assert(i.hasNext());
		System.assertEquals('1', i.next().text);
		System.assertEquals(false, i.hasNext());
		
		e = new RT_Expression('  1   +   2    ');
		i = e.getExpressionTokenizer();
		System.assertEquals('1', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assert(i.hasNext());
		System.assertEquals('2', i.next().text);
		System.assertEquals(false, i.hasNext());
	}
	
	@isTest static void testTokenizerNextThrows() {
		try {
			RT_Expression e = new RT_Expression('1');
			Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
			System.assertEquals('1', i.next().text);
			System.assertEquals(false, i.hasNext());
			i.next();
			System.assert(false, 'Expected an exception');
		}
		catch (Exception e) {
			System.assertEquals('RT_Expression.IllegalStateException', e.getTypeName());
		}
	}
	
	@isTest static void testTokenizer1() {
		RT_Expression e = new RT_Expression('1+2');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('1', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assertEquals('2', i.next().text);
	}
	
	@isTest static void testTokenizer2() {
		RT_Expression e = new RT_Expression('1 + 2');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('1', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assertEquals('2', i.next().text);
	}
	
	@isTest static void testTokenizer3() {
		RT_Expression e = new RT_Expression(' 1 + 2 ');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('1', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assertEquals('2', i.next().text);
	}
	
	@isTest static void testTokenizer4() {
		RT_Expression e = new RT_Expression('1+2-3/4*5');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('1', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assertEquals('2', i.next().text);
		System.assertEquals('-', i.next().text);
		System.assertEquals('3', i.next().text);
		System.assertEquals('/', i.next().text);
		System.assertEquals('4', i.next().text);
		System.assertEquals('*', i.next().text);
		System.assertEquals('5', i.next().text);
	}
	
	@isTest static void testTokenizer5() {
		RT_Expression e = new RT_Expression('1+2.1-3.45/4.982*5.0');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('1', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assertEquals('2.1', i.next().text);
		System.assertEquals('-', i.next().text);
		System.assertEquals('3.45', i.next().text);
		System.assertEquals('/', i.next().text);
		System.assertEquals('4.982', i.next().text);
		System.assertEquals('*', i.next().text);
		System.assertEquals('5.0', i.next().text);
	}
	
	@isTest static void testTokenizer6() {
		RT_Expression e = new RT_Expression('-3+4*-1');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('-3', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assertEquals('4', i.next().text);
		System.assertEquals('*', i.next().text);
		System.assertEquals('-1', i.next().text);
	}
	
	@isTest static void testTokenizer7() {
		RT_Expression e = new RT_Expression('(-3+4)*-1/(7-(5*-8))');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('(', i.next().text);
		System.assertEquals('-3', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assertEquals('4', i.next().text);
		System.assertEquals(')', i.next().text);
		System.assertEquals('*', i.next().text);
		System.assertEquals('-1', i.next().text);
		System.assertEquals('/', i.next().text);
		System.assertEquals('(', i.next().text);
		System.assertEquals('7', i.next().text);
		System.assertEquals('-', i.next().text);
		System.assertEquals('(', i.next().text);
		System.assertEquals('5', i.next().text);
		System.assertEquals('*', i.next().text);
		System.assertEquals('-8', i.next().text);
		System.assertEquals(')', i.next().text);
		System.assertEquals(')', i.next().text);
	}
	
	@isTest static void testTokenizer8() {
		RT_Expression e = new RT_Expression('(1.9+2.8)/4.7');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('(', i.next().text);
		System.assertEquals('1.9', i.next().text);
		System.assertEquals('+', i.next().text);
		System.assertEquals('2.8', i.next().text);
		System.assertEquals(')', i.next().text);
		System.assertEquals('/', i.next().text);
		System.assertEquals('4.7', i.next().text);
	}
	
	@isTest static void testTokenizerStrings() {
		RT_Expression e;
		Iterator<RT_Expression.Token> i;
		RT_Expression.Token tk;
		
		e = new RT_Expression('1+(IF("foo" != "bar", 1, 0)*2)');
		i = e.getExpressionTokenizer();
		
		System.assertEquals('1', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.NUMBERX, tk.type);
		System.assertEquals('+', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.OPERATOR, tk.type);
		System.assertEquals('(', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.LEFT_PAREN, tk.type);
		System.assertEquals('IF', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.FUNCTION, tk.type);
		System.assertEquals('(', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.LEFT_PAREN, tk.type);
		System.assertEquals('__STR0__', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.VARIABLE, tk.type);
		System.assertEquals('!=', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.OPERATOR, tk.type);
		System.assertEquals('__STR1__', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.VARIABLE, tk.type);
		System.assertEquals(',', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.COMMA, tk.type);
		System.assertEquals('1', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.NUMBERX, tk.type);
		System.assertEquals(',', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.COMMA, tk.type);
		System.assertEquals('0', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.NUMBERX, tk.type);
		System.assertEquals(')', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.RIGHT_PAREN, tk.type);
		System.assertEquals('*', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.OPERATOR, tk.type);
		System.assertEquals('2', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.NUMBERX, tk.type);
		System.assertEquals(')', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.RIGHT_PAREN, tk.type);
		System.assertEquals(false, i.hasNext());
	}
	
	@isTest static void testTokenizerStringConcat() {
		RT_Expression e;
		Iterator<RT_Expression.Token> i;
		RT_Expression.Token tk;
		
		e = new RT_Expression('"foo" + "bar" == "foobar"');
		i = e.getExpressionTokenizer();
		
		System.assertEquals('__STR0__', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.VARIABLE, tk.type);
		System.assertEquals(e.variables.get('__STR0__'), 'foo');
		System.assertEquals('+', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.OPERATOR, tk.type);
		System.assertEquals('__STR1__', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.VARIABLE, tk.type);
		System.assertEquals(e.variables.get('__STR1__'), 'bar');
		System.assertEquals('==', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.OPERATOR, tk.type);
		System.assertEquals('__STR2__', (tk = i.next()).text);
		System.assertEquals(RT_Expression.TokenType.VARIABLE, tk.type);
		System.assertEquals(e.variables.get('__STR2__'), 'foobar');
		System.assertEquals(false, i.hasNext());
	}
	
	@isTest static void testTokenizerFunction1() {
		RT_Expression e = new RT_Expression('ABS(3.5)');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('ABS', i.next().text);
		System.assertEquals('(', i.next().text);
		System.assertEquals('3.5', i.next().text);
		System.assertEquals(')', i.next().text);
	}
	
	@isTest static void testTokenizerFunction2() {
		RT_Expression e = new RT_Expression('3-ABS(3.5)/9');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('3', i.next().text);
		System.assertEquals('-', i.next().text);
		System.assertEquals('ABS', i.next().text);
		System.assertEquals('(', i.next().text);
		System.assertEquals('3.5', i.next().text);
		System.assertEquals(')', i.next().text);
		System.assertEquals('/', i.next().text);
		System.assertEquals('9', i.next().text);
	}
	@isTest static void testTokenizerFunction3() {
		RT_Expression e = new RT_Expression('MAX(3.5,5.2)');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('MAX', i.next().text);
		System.assertEquals('(', i.next().text);
		System.assertEquals('3.5', i.next().text);
		System.assertEquals(',', i.next().text);
		System.assertEquals('5.2', i.next().text);
		System.assertEquals(')', i.next().text);
	}
	
	@isTest static void testTokenizerFunction4() {
		RT_Expression e = new RT_Expression('3-MAX(3.5,5.2)/9');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('3', i.next().text);
		System.assertEquals('-', i.next().text);
		System.assertEquals('MAX', i.next().text);
		System.assertEquals('(', i.next().text);
		System.assertEquals('3.5', i.next().text);
		System.assertEquals(',', i.next().text);
		System.assertEquals('5.2', i.next().text);
		System.assertEquals(')', i.next().text);
		System.assertEquals('/', i.next().text);
		System.assertEquals('9', i.next().text);
	}
	
	@isTest static void testTokenizerFunction5() {
		RT_Expression e = new RT_Expression('3/MAX(-3.5,-5.2)/9');
		Iterator<RT_Expression.Token> i = e.getExpressionTokenizer();
		
		System.assertEquals('3', i.next().text);
		System.assertEquals('/', i.next().text);
		System.assertEquals('MAX', i.next().text);
		System.assertEquals('(', i.next().text);
		System.assertEquals('-3.5', i.next().text);
		System.assertEquals(',', i.next().text);
		System.assertEquals('-5.2', i.next().text);
		System.assertEquals(')', i.next().text);
		System.assertEquals('/', i.next().text);
		System.assertEquals('9', i.next().text);
	}
	
	/* Var Args
	 */
	
	@isTest static void testVarArgsSimple() {
		RT_Expression e = new RT_Expression('max(1)');
		System.assertEquals('1', e.eval().toPlainString());
		
		e = new RT_Expression('max(4,8)');
		System.assertEquals('8', e.eval().toPlainString());
		
		e = new RT_Expression('max(12,4,8)');
		System.assertEquals('12', e.eval().toPlainString());
		
		e = new RT_Expression('max(12,4,8,16,32)');
		System.assertEquals('32', e.eval().toPlainString());
	}
	
	@isTest static void testVarArgsNested() {
		RT_Expression e = new RT_Expression('max(1,2,max(3,4,5,max(9,10,3,4,5),8),7)');
		System.assertEquals('10', e.eval().toPlainString());
	}
	
	@isTest static void testVarArgsZero() {
		RT_Expression e = new RT_Expression('max(0)');
		System.assertEquals('0', e.eval().toPlainString());
		
		e = new RT_Expression('max(0,3)');
		System.assertEquals('3', e.eval().toPlainString());
		
		e = new RT_Expression('max(2,0,-3)');
		System.assertEquals('2', e.eval().toPlainString());
		
		e = new RT_Expression('max(-2,0,-3)');
		System.assertEquals('0', e.eval().toPlainString());
		
		e = new RT_Expression('max(0,0,0,0)');
		System.assertEquals('0', e.eval().toPlainString());
	}
	
	@isTest static void testVarArgsError() {
		String err = '';
		RT_Expression e = new RT_Expression('max()');
		try {
			e.eval();
		}
		catch (RT_Expression.ExpressionException ex) {
			err = ex.getMessage();
		}
		System.assertEquals('Function MAX expected -1 parameters, got 0', err);
	}
	
	@isTest static void testVarArgsCustomFunction1() {
		RT_Expression e = new RT_Expression('3 * AVG(2,4)');
		RT_Expression.addFunction(new AvgFunction('AVG', -1));
		System.assertEquals('9', e.eval().toPlainString());
	}
	
	@isTest static void testVarArgsCustomFunction2() {
		RT_Expression e = new RT_Expression('4 * AVG(2,4,6,8,10,12)');
		RT_Expression.addFunction(new AvgFunction('AVG', -1));
		System.assertEquals('28', e.eval().toPlainString());
	}
	
	/* Variables
	 */
	
	@isTest static void testVars() {
		String actual, ex;
		
		actual = new RT_Expression('PI').eval() + '';
		System.assertEquals('3.141593', actual);
		
		actual = new RT_Expression('PI').setPrecision(0).eval() + '';
		System.assertEquals('3.141592653589793', actual);
		
		actual = new RT_Expression('PI').setPrecision(34).eval() + '';
		System.assertEquals('3.141592653589793', actual);
		
		actual = new RT_Expression('PI').setPrecision(16).eval() + '';
		System.assertEquals('3.141592653589793', actual);
		
		actual = new RT_Expression('PI').setPrecision(7).eval() + '';
		System.assertEquals('3.141593', actual);
		
		actual = new RT_Expression('PI*2.0').eval() + '';
		System.assertEquals('6.283186', actual);
		
		actual = new RT_Expression('E').eval() + '';
		System.assertEquals('2.718282', actual);
		
		actual = new RT_Expression('e*2.0').eval() + '';
		System.assertEquals('5.436564', actual);
		
		actual = new RT_Expression('E*2e3').eval() + '';
		System.assertEquals('5436.564', actual);
		
		actual = new RT_Expression('3*x').setVariable('x', 7).eval() + '';
		System.assertEquals('21', actual);
		
		actual = new RT_Expression('(a^2)+(b^2)').setVariable('a', 2).setVariable('b', 4).eval().toPlainString();
		System.assertEquals('20', actual);
		
		actual = new RT_Expression('a^(2+b)^2').setVariable('a', '2').setVariable('b', '4').eval().toPlainString();
		System.assertEquals('68719480000', actual);
		
		actual = new RT_Expression('(a == null && b != null) && true').with('a', null).with('b', 1).eval().toPlainString();
		System.assertEquals('1', actual);
		
		actual = new RT_Expression('a && b').with('a', true).with('b', false).eval().toPlainString();
		System.assertEquals('0', actual);
		
		actual = new RT_Expression('(a || NOT(b)) && a || b').with('a', true).with('b', false).eval().toPlainString();
		System.assertEquals('1', actual);
		
		ex = 'IF(first.name + " " + last.name == "James Baxter", 1, 2) * 10';
		System.assertEquals(10, new RT_Expression(ex).with('first.name', 'James').with('last.name', 'Baxter').eval());
		
		ex = 'IF(last.name + ", " + first.name == "Baxter, James", 1, 2) * 10';
		System.assertEquals(10, new RT_Expression(ex, new Map<String, Object> {
			'first.name' => 'James',
			'last.name' => 'Baxter'
		}).eval());
		
		System.assertEquals(300000, new RT_Expression('3*x').with('x', Decimal.valueOf('100000')).eval());
		System.assertEquals(300000, new RT_Expression('3*x').with('x', Double.valueOf('100000')).eval());
		System.assertEquals(300000, new RT_Expression('3*x').with('x', Integer.valueOf('100000')).eval());
		System.assertEquals(300000, new RT_Expression('3*x').with('x', Long.valueOf('100000')).eval());
	}

	@isTest static void testInvalidVariableType() {
		Datetime value = Datetime.now();
		try {
			new RT_Expression('x').with('x', value);
			System.assert(false);
		}
		catch (RT_Expression.IllegalArgumentException e) {
			System.assertEquals('Object value \'' + value + '\' is not of a supported type', e.getMessage());
		}
	}
	
	@isTest static void testSubstitution() {
		RT_Expression e = new RT_Expression('x+y');
		
		System.assertEquals('2', e.with('x', '1').with('y', '1').eval().toPlainString());
		System.assertEquals('1', e.with('y', '0').eval().toPlainString());
		System.assertEquals('0', e.with('x', '0').eval().toPlainString());
	}
	
	@isTest static void testNullSubstitution() {
		RT_Expression e = new RT_Expression('x+y');
		
		System.assertEquals('1', e.with('x', null).with('y', '1').eval().toPlainString());
		System.assertEquals('0', e.with('y', null).eval().toPlainString());
		System.assertEquals('1', e.with('x', '1').eval().toPlainString());
	}
	
	@isTest static void testWith() {
		String actual;
		actual = new RT_Expression('3*x').with('x', 7).eval() + '';
		System.assertEquals('21', actual);
		
		actual = new RT_Expression('(a^2)+(b^2)').with('a', 2).with('b', 4).eval().toPlainString();
		System.assertEquals('20', actual);
		
		actual = new RT_Expression('a^(2+b)^2').with('a', '2').with('b', '4').eval().toPlainString();
		System.assertEquals('68719480000', actual);
		
		actual = new RT_Expression('_a^(2+_b)^2').with('_a', '2').with('_b', '4').eval().toPlainString();
		System.assertEquals('68719480000', actual);
	}
	
	@isTest static void testNames() {
		System.assertEquals('21', new RT_Expression('3*longname').with('longname', 7).eval() + '');
		System.assertEquals('21', new RT_Expression('3*longname1').with('longname1', 7).eval() + '');
		System.assertEquals('21', new RT_Expression('3*_longname1').with('_longname1', 7).eval() + '');
	}
	
	@isTest static void testQuadraticFormula() {
		System.debug('Evaluating: (-b + SQRT(b^2 - 4*a*c)) / (2*a); a=1, b=4, c=3');
		Decimal x1 = new RT_Expression('((b*(-1)) + SQRT(b^2 - 4*a*c)) / (2*a)').with('a', 1).with('b', 4).with('c', 3).eval();
		System.debug('Solution 1 = ' + x1);
		System.debug('Evaluating: (-b - SQRT(b^2 - 4*a*c)) / (2*a); a=1, b=4, c=3');
		Decimal x2 = new RT_Expression('((b*(-1)) - SQRT(b^2 - 4*a*c)) / (2*a)').with('a', 1).with('b', 4).with('c', 3).eval();
		System.debug('Solution 2 = ' + x2);
		System.assertEquals(-1, x1);
		System.assertEquals(-3, x2);
	}
	
	@isTest static void testEqualAndHashCode() {
		RT_Expression e1 = new RT_Expression('((b*(-1)) + SQRT(b^2 - 4*a*c)) / (2*a)').with('a', 1).with('b', 4).with('c', 3);
		RT_Expression e2 = new RT_Expression('((b*(-1)) + SQRT(b^2 - 4*a*c)) / (2*a)').with('a', 1).with('b', 4).with('c', 3);
		System.assert(e1.equals(e2));
		System.assert(e1.hashCode() == e2.hashCode());
	}
	
	@isTest static void testNotEqualAndHashCode1() {
		RT_Expression e1 = new RT_Expression('((b*(-1)) + SQRT(b^2 - 4*a*c)) / (2*a)').with('a', 1).with('b', 4).with('c', 3);
		RT_Expression e2 = new RT_Expression('((b*(-1)) - SQRT(b^2 - 4*a*c)) / (2*a)').with('a', 1).with('b', 4).with('c', 3);
		System.assert(!e1.equals(e2));
		System.assert(e1.hashCode() != e2.hashCode());
	}
	
	@isTest static void testNotEqualAndHashCode2() {
		RT_Expression e1 = new RT_Expression('((b*(-1)) + SQRT(b^2 - 4*a*c)) / (2*a)').with('a', 1).with('b', 4).with('c', 3);
		RT_Expression e2 = new RT_Expression('((b*(-1)) + SQRT(b^2 - 4*a*c)) / (2*a)').with('a', 1).with('b', 5).with('c', 3);
		System.assert(!e1.equals(e2));
		System.assert(e1.hashCode() != e2.hashCode());
	}
	
	@isTest static void testMismatchedParens1() {
		String err;
		try {
			new RT_Expression('(').eval();
		}
		catch (Exception e) {
			err = e.getMessage();
		}
		System.assertEquals('Mismatched parentheses', err);
	}
	
	@isTest static void testMismatchedParens2() {
		String err;
		try {
			new RT_Expression('4)').eval();
		}
		catch (Exception e) {
			err = e.getMessage();
		}
		System.assertEquals('Mismatched parentheses', err);
	}
	
	@isTest static void testFunctionError() {
		String err;
		try {
			new RT_Expression('MIN, ').eval();
		}
		catch (Exception e) {
			err = e.getMessage();
		}
		System.assertEquals('Parse error for function \'MIN\'', err);
	}
}
