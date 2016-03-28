/*
 * Copyright 2012 Udo Klimaschewski
 *
 * http://UdoJava.com/
 * http://about.me/udo.klimaschewski
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

/**
 * Apex EvalEx - Apex Expression Evaluator
 * An Apex port of EvalEx @ https://github.com/uklimaschewski/EvalEx
 */
public class RT_Expression implements IExpression {

	interface IExpression {
		Decimal eval();
		String toRPN();
		RT_Expression setPrecision(Integer precision);
		RT_Expression setRoundingMode(RoundingMode roundingMode);
		RT_Expression setVariable(String variable, Decimal value);
		RT_Expression setVariable(String variable, String value);
		RT_Expression with(String variable, Decimal value);
		RT_Expression with(String variable, String value);
		Iterator<String> getExpressionTokenizer();
		Set<String> getDeclaredVariables();
		Set<String> getDeclaredOperators();
		Set<String> getDeclaredFunctions();
	}
	
	public static final Decimal ZERO = 0, ONE = 1, MAX_INTEGER, MIN_INTEGER;
	
	static {
		MAX_INTEGER = Math.pow(2, 31).intValue();
		MIN_INTEGER = MAX_INTEGER + 1;
	}
	
	/**
	 * All defined operators with name and implementation
	 */
	private static Map<String, Operator> operators;
	
	/**
	 * All defined functions with name and implementation
	 */
	private static Map<String, Function> functions;
	
	static {
		operators = new Map<String, Operator>();
		functions = new Map<String, Function>();
		
		// default operators
		addOperator(new AddOperator('+', 20, Associability.LEFT));
		addOperator(new SubtractOperator('-', 20, Associability.LEFT));
		addOperator(new MultiplyOperator('*', 30, Associability.LEFT));
		addOperator(new DivideOperator('/', 30, Associability.LEFT));
		addOperator(new ModOperator('%', 30, Associability.LEFT));
		addOperator(new PowOperator('^', 40, Associability.RIGHT));
		addOperator(new AndOperator('&&', 4, Associability.RIGHT));
		addOperator(new OrOperator('||', 2, Associability.RIGHT));
		addOperator(new GreaterOperator('>', 10, Associability.RIGHT));
		addOperator(new GreaterOrEqualOperator('>=', 10, Associability.RIGHT));
		addOperator(new LessOperator('<', 10, Associability.RIGHT));
		addOperator(new LessEqualOperator('<=', 10, Associability.RIGHT));
		addOperator(new EqualOperator('=', 7, Associability.RIGHT));
		addOperator(new EqualOperator('==', 7, Associability.RIGHT));
		addOperator(new NotEqualOperator('!=', 7, Associability.RIGHT));
		addOperator(new NotEqualOperator('<>', 7, Associability.RIGHT));
		
		// default functions
		addFunction(new NotFunction('NOT', 1));
		addFunction(new IfFunction('IF', 3));
		addFunction(new RandomFunction('RANDOM', 0));
		addFunction(new SinFunction('SIN', 1));
		addFunction(new CosFunction('COS', 1));
		addFunction(new TanFunction('TAN', 1));
		addFunction(new AsinFunction('ASIN', 1));
		addFunction(new AcosFunction('ACOS', 1));
		addFunction(new AtanFunction('ATAN', 1));
		addFunction(new SinhFunction('SINH', 1));
		addFunction(new CoshFunction('COSH', 1));
		addFunction(new TanhFunction('TANH', 1));
		addFunction(new RadFunction('RAD', 1));
		addFunction(new DegFunction('DEG', 1));
		addFunction(new MaxFunction('MAX', -1));
		addFunction(new MinFunction('MIN', -1));
		addFunction(new AbsFunction('ABS', 1));
		addFunction(new LogFunction('LOG', 1));
		addFunction(new Log10Function('LOG10', 1));
		addFunction(new RoundFunction('ROUND', 2));
		addFunction(new FloorFunction('FLOOR', 1));
		addFunction(new CeilingFunction('CEILING', 1));
		addFunction(new SqrtFunction('SQRT', 1));
	}
	
	/**
	 * The MathContext to use for calculations
	 */
	public MathContext mc;
	
	/**
	 * The original infix expression
	 */
	private String expression;
	
	/**
	 * The cached RPN (Reverse Polish Notation) of the expression
	 */
	private List<String> rpn;
	
	/**
	 * All defined variables with name and value
	 */
	private Map<String, Decimal> variables = new Map<String, Decimal>();
	
	/**
	 * Creates a new expression instance from an expression string with a given
	 * default match context of MathContext#DECIMAL32.
	 *
	 * @param expression the expression. E.g. `'2.4*sin(3)/(2-4)'` or `'sin(y)>0 & max(z, 3)>3'`
	 */
	public RT_Expression(String expression) {
		this(expression, new MathContext(7, RoundingMode.HALF_EVEN));
	}
	
	/**
	 * Creates a new expression instance from an expression string with a given
	 * default match context.
	 *
	 * @param expression the expression, eg: `2.4*sin(3)/(2-4)` or `sin(y)>0 && max(z, 3)>3`
	 */
	public RT_Expression(String expression, MathContext mc) {
		this.expression = expression;
		this.mc = mc;
		
		variables.put('PI', Math.PI);
		variables.put('TRUE', ONE);
		variables.put('FALSE', ZERO);
	}
	
	/**
	 * Implementation of the Shunting Yard algorithm to transform an
	 * infix expression to a RPN expression.
	 *
	 * @param expression the input expression in infx.
	 * @return an RPN representation of the expression, with
	 *         each token as a list member.
	 */
	private List<String> shuntingYard(String expression) {
		List<String> outputQueue = new List<String>();
		RT_Stack stack = new RT_Stack();
		
		Tokenizer tokenizer = new Tokenizer(expression, this);
		
		String lastFunction;
		String previousToken;
		while (tokenizer.hasNext()) {
			String token = tokenizer.next();
			if (isNumber(token)) {
				outputQueue.add(token);
			}
			else if (variables.containsKey(token.toUpperCase())) {
				outputQueue.add(token);
			}
			else if (functions.containsKey(token.toUpperCase())) {
				stack.push(token);
				lastFunction = token;
			}
			else if (charAt(token, 0).isAlpha()) {
				stack.push(token);
			}
			else if (token == ',') {
				while (!stack.isEmpty() && stack.peek() != '(') {
					outputQueue.add((String) stack.pop());
				}
				if (stack.isEmpty()) {
					throw new ExpressionException('Parse error for function \'' + lastFunction + '\'');
				}
			}
			else if (operators.containsKey(token)) {
				Operator o1 = operators.get(token);
				String token2 = stack.isEmpty() ? null : (String) stack.peek();
				while (
				    token2 != null &&
				    operators.containsKey(token2) && (
				        o1.isLeftAssoc() && o1.getPrecedence() <= operators.get(token2).getPrecedence() ||
				        o1.getPrecedence() < operators.get(token2).getPrecedence()
				    )
				) {
					outputQueue.add((String) stack.pop());
					token2 = stack.isEmpty() ? null : (String) stack.peek();
				}
				stack.push(token);
			}
			else if (token == '(') {
				if (previousToken != null) {
					if (isNumber(previousToken)) {
						throw new ExpressionException('Missing operator at character position ' + tokenizer.getPos());
					}
					// if the ( is preceded by a valid function, then it
					// denotes the start of a parameter list
					if (functions.containsKey(previousToken.toUpperCase())) {
						outputQueue.add(token);
					}
				}
				stack.push(token);
			}
			else if (token == ')') {
				while (!stack.isEmpty() && !'('.equals(stack.peek())) {
					outputQueue.add((String) stack.pop());
				}
				if (stack.isEmpty()) {
					throw new ExpressionException('Mismatched parentheses');
				}
				stack.pop();
				if (!stack.isEmpty()
				    && functions.containsKey(((String) stack.peek()).toUpperCase())) {
					outputQueue.add((String) stack.pop());
				}
			}
			previousToken = token;
		}
		while (!stack.isEmpty()) {
			String element = (String) stack.pop();
			if (element == '(' || element == ')') {
				throw new ExpressionException('Mismatched parentheses');
			}
			if (!operators.containsKey(element)) {
				throw new ExpressionException('Unknown operator or function: ' + element);
			}
			outputQueue.add(element);
		}
		return outputQueue;
	}
	
	/**
	 * Evaluates the expression.
	 *
	 * @return the result of the expression.
	 */
	public Decimal eval() {
		RT_Stack stack = new RT_Stack();
		
		for (String token : getRPN()) {
			if (operators.containsKey(token)) {
				Decimal v1 = (Decimal) stack.pop();
				Decimal v2 = (Decimal) stack.pop();
				stack.push(operators.get(token).eval(v2, v1, this.mc));
			}
			else if (variables.containsKey(token.toUpperCase())) {
				stack.push(round(variables.get(token.toUpperCase()), mc));
			}
			else if (functions.containsKey(token.toUpperCase())) {
				Function f = functions.get(token.toUpperCase());
				List<Decimal> p = new List<Decimal>();
				// pop parameters off the stack until we hit the start of
				// this function's parameter list
				while (!stack.isEmpty() && stack.peek() != null) {
					if (p.isEmpty()) {
						p.add((Decimal) stack.pop());
					}
					else {
						p.add(0, (Decimal) stack.pop());
					}
				}
				if (stack.peek() == null) {
					stack.pop();
				}
				if (!f.numParamsVaries() && p.size() != f.getNumParams()) {
					throw new ExpressionException('Function ' + token + ' expected ' + f.getNumParams() + ' parameters, got ' + p.size());
				}
				
				stack.push(f.eval(p, this.mc));
			}
			else if (token == '(') {
				stack.push(null);
			}
			else {
				stack.push(Decimal.valueOf(token));
			}
		}
		return ((Decimal) stack.pop()).stripTrailingZeros();
	}
	
	/**
	 * Sets the precision for expression evaluation
	 * @param precision the new precision
	 * @return the expression, allows to chain methods
	 */
	public RT_Expression setPrecision(Integer precision) {
		this.mc.precision = precision;
		return this;
	}
	
	/**
	 * Sets the rounding mode for expression evaluation
	 *
	 * @param rounding the new rounding mode
	 * @return the expression, allows to chain methods
	 */
	public RT_Expression setRoundingMode(RoundingMode roundingMode) {
		this.mc.roundingMode = roundingMode;
		return this;
	}
	
	/**
	 * Adds an operator to the list of supported operators
	 *
	 * @param operator The operator to add
	 * @return the previous operator with that name, or `null` if there was none
	 */
	public static Operator addOperator(Operator operator) {
		return operators.put(operator.getOper(), operator);
	}
	
	/**
	 * Adds a function to the list of supported functions
	 *
	 * @param function The function to add
	 * @return the previous operator with that name, or `null` if there was none
	 */
	public static Function addFunction(Function function) {
		return functions.put(function.getName().toUpperCase(), function);
	}
	
	/**
	 * Sets a variable value
	 *
	 * @param variable The variable name.
	 * @param value The variable value.
	 * @return the expression, allows to chain methods.
	 */
	public RT_Expression setVariable(String variable, Decimal value) {
		variables.put(variable.toUpperCase(), value);
		return this;
	}
	
	/**
	 * Sets a variable value.
	 *
	 * @param variable the variable to set
	 * @param value the variable value
	 * @return the expression for chaining
	 */
	public RT_Expression setVariable(String variable, String value) {
		if (isNumber(value)) {
			variables.put(variable.toUpperCase(), Decimal.valueOf(value));
		}
		else {
			expression = expression.replaceAll('(?i)\\b' + variable + '\\b', '(' + value + ')');
			rpn = null;
		}
		return this;
	}
	
	/**
	 * Sets a variable value.
	 *
	 * @param variable The variable to set
	 * @param value The variable value
	 * @return the expression for chaining
	 */
	public RT_Expression with(String variable, Decimal value) {
		return setVariable(variable.toUpperCase(), value);
	}
	
	/**
	 * Sets a variable value.
	 *
	 * @param variable The variable to set
	 * @param value The variable value
	 * @return the expression for chaining
	 */
	public RT_Expression with(String variable, String value) {
		return setVariable(variable.toUpperCase(), value);
	}
	
	/**
	 * Get an iterator for this expression, allows iterating over an expression
	 * token by token.
	 *
	 * @return a new iterator instance for this expression.
	 */
	public Iterator<String> getExpressionTokenizer() {
		return new Tokenizer(this.expression, this);
	}
	
	/**
	 * Cached access to the RPN notation of this expression, ensures only one
	 * calculation of the RPN per expression instance. If no cached instance
	 * exists, a new one will be created and put to the cache.
	 *
	 * @return the cached RPN instance.
	 */
	private List<String> getRPN() {
		if (rpn == null) {
			rpn = shuntingYard(this.expression);
			validate(rpn);
		}
		return rpn;
	}
	
	/**
	 * Check that the expression have enough numbers and variables to fit the
	 * requirements of the operators and functions, also check
	 * for only 1 result stored at the end of the evaluation.
	 *
	 */
	private void validate(List<String> rpn) {
		/*-
		* Thanks to Norman Ramsey:
		* http://http://stackoverflow.com/questions/789847/postfix-notation-validation
		*/
		Integer counter = 0;
		RT_Stack params = new RT_Stack();
		for (String token : rpn) {
			if ('('.equals(token)) {
				// is this a nested function call?
				if (!params.isEmpty()) {
					// increment the current function's param count
					// (the return of the nested function call
					// will be a parameter for the current function)
					params.push((Integer) params.pop() + 1);
				}
				// start a new parameter count
				params.push(0);
			}
			else if (!params.isEmpty()) {
				Integer inc = (Integer) params.pop() + 1;
				if (functions.containsKey(token.toUpperCase())) {
					// remove the parameters and the ( from the counter
					counter -= inc;
				}
				else {
					// increment the current function's param count
					params.push(inc);
				}
			}
			else if (operators.containsKey(token)) {
				//we only have binary operators
				counter -= 2;
			}
			if (counter < 0) {
				throw new ExpressionException('Too many operators or functions at: ' + token);
			}
			counter++;
		}
		if (counter > 1) {
			throw new ExpressionException('Too many numbers or variables');
		}
		else if (counter < 1) {
			throw new ExpressionException('Empty expression');
		}
	}
	
	/**
	 * Get a string representation of the RPN (Reverse Polish Notation) for this
	 * expression.
	 *
	 * @return a string with the RPN representation for this expression.
	 */
	public String toRPN() {
		String result = '';
		for (String st : getRPN()) {
			if (result.length() != 0) {
				result += ' ';
			}
			result += st;
		}
		return result;
	}
	
	/**
	 * Is the string a number?
	 *
	 * @param st the string
	 * @return true if the input string is a number
	 */
	public static Boolean isNumber(String st) {
		if (String.isBlank(st)) {
			return false;
		}
		String s = charAt(st, 0);
		if (s == '-' && st.length() == 1) {
			return false;
		}
		if (s == '+' && st.length() == 1) {
			return false;
		}
		if (s == 'e') {
			return false;
		}
		for (String ch : st.split('')) {
			if (ch != '' && !ch.isNumeric() && ch != '-' && ch != '.' && ch != 'e' && ch != '+') {
				return false;
			}
		}
		return true;
	}
	
	/**
	 * Converts an angle measured in degrees to an approximately
	 * equivalent angle measured in radians. The conversion from
	 * degrees to radians is generally inexact.
	 *
	 * @param angdeg an angle, in degrees
	 * @return measurement of the angle `angdeg` in radians.
	 */
	private static Decimal toRadians(Decimal angdeg) {
		return angdeg / 180.0 * Math.PI;
	}
	
	/**
	 * Converts an angle measured in radians to an approximately
	 * equivalent angle measured in degrees. The conversion from
	 * radians to degrees is generally inexact; users should
	 * not expect `cos(toRadians(90.0))` to exactly equal `0.0`.
	 *
	 * @param angrad an angle, in radians
	 * @return the measurement of the angle `angrad` in degrees.
	 */
	private static Decimal toDegrees(Decimal angrad) {
		return angrad * 180.0 / Math.PI;
	}
	
	/**
	 * Returns the string of a character at `ind` in `str`
	 */
	private static String charAt(String str, Integer ind) {
		return String.fromCharArray(new List<Integer> {str.charAt(ind)});
	}
	
	/**
	 * Round a Decimal given a MathContext
	 */
	private static Decimal round(Decimal d, MathContext mc) {
		Integer precision = mc.precision;
		RoundingMode roundingMode = mc.roundingMode;
		Integer numToChop = d.precision() - precision;
		if (precision == 0 || numToChop <= 0) {
			return d;
		}
		Decimal div = Math.pow(10, Math.min(33 - precision, numToChop));
		System.debug('div=' + div);
		System.debug('d=' + d);
		Integer scale = Math.min(33, Math.max(-33, d.scale()));
		System.debug('scale=' + scale);
		Decimal rounded = d.divide(div, scale, roundingMode);
		System.debug('rounded=' + rounded);
		rounded = rounded * div;
		System.debug('rounded=' + rounded);
		return rounded;
	}
	
	/**
	 * Exposing declared variables in the expression
	 * @return declared variables
	 */
	public Set<String> getDeclaredVariables() {
		return variables.keySet();
	}
	
	/**
	 * Exposing declared operators in the expression
	 * @return declared operators
	 */
	public Set<String> getDeclaredOperators() {
		return operators.keySet();
	}
	
	/**
	 * Exposing declared functions
	 * @return declared functions
	 */
	public Set<String> getDeclaredFunctions() {
		return functions.keySet();
	}
	
	/**
	 * Abstract definition of a supported expression function. A function is
	 * defined by a name, the number of parameters and the actual processing
	 * implementation.
	 */
	public abstract class Function {
	
		/**
		 * Name of this function.
		 */
		protected String name;
		
		/**
		 * Number of parameters expected for this function.
		 * `-1` denotes a variable number of parameters.
		 */
		protected Integer numParams;
		
		/**
		 * Creates a new function with given name and parameter count
		 * @param name name of the function
		 * @param numParams number of parameters for this function; `-1` denotes
		 *                  a variable number of parameters
		 */
		public Function(String name, Integer numParams) {
			this.name = name.toUpperCase();
			this.numParams = numParams;
		}
		
		public Function() {
			throw new UnsupportedOperationException();
		}
		
		public String getName() {
			return name;
		}
		
		public Integer getNumParams() {
			return numParams;
		}
		
		public Boolean numParamsVaries() {
			return numParams < 0;
		}
		
		/**
		 * Implementation for this function.
		 *
		 * @param parameters passed by evaluator as a List of Decimal values
		 * @return a new Decimal value as a computing result
		 */
		public abstract Decimal eval(List<Decimal> parameters, MathContext mc);
	}
	
	/**
	 * Abstract definition of a supported operator. An operator is defined by
	 * its name (pattern), precedence, and if it is left or right associative.
	 */
	public abstract class Operator {
		/**
		 * This operators name (pattern).
		 */
		protected String oper;
		/**
		 * Operators precedence.
		 */
		protected Integer precedence;
		/**
		 * Operator is left associative.
		 */
		protected Associability assoc;
		
		/**
		 * Creates a new operator.
		 *
		 * @param oper operator name (pattern)
		 * @param precedence operator precedence
		 * @param assoc true if the operator is left associative, else false
		 */
		public Operator(String oper, Integer precedence, Associability assoc) {
			this.oper = oper;
			this.precedence = precedence;
			this.assoc = assoc;
		}
		
		public String getOper() {
			return oper;
		}
		
		public Integer getPrecedence() {
			return precedence;
		}
		
		public Boolean isLeftAssoc() {
			return assoc == Associability.LEFT;
		}
		
		/**
		 * Implementation for this operator
		 *
		 * @param v1 operand 1
		 * @param v2 operand 2
		 * @return result of the operation
		 */
		public abstract Decimal eval(Decimal v1, Decimal v2, MathContext mc);
	}
	
	/**
	 * Expression tokenizer that allows to iterate over a String
	 * expression token by token. Blank characters will be skipped.
	 */
	public class Tokenizer implements Iterator<String> {
	
		private RT_Expression expr;
		
		/**
		 * Actual position in expression string.
		 */
		private Integer pos = 0;
		
		/**
		 * The original input expression.
		 */
		private String input;
		/**
		 * The previous token or `null` if none.
		 */
		private String previousToken;
		
		/**
		 * Creates a new tokenizer for an expression.
		 *
		 * @param input expression string
		 */
		public Tokenizer(String input, RT_Expression expr) {
			this.expr = expr;
			this.input = input.trim();
		}
		
		public Boolean hasNext() {
			return pos < input.length();
		}
		
		/**
		 * Peek at the next character, without advancing the iterator.
		 *
		 * @return the next character or character 0, if at end of string.
		 */
		private String peekNextChar() {
			if (pos < (input.length() - 1)) {
				return charAt(input, pos + 1);
			}
			else {
				return '';
			}
		}
		
		public String next() {
			String token = '';
			if (pos >= input.length()) {
				return previousToken = null;
			}
			String ch = charAt(input, pos);
			while (ch.isWhitespace() && pos < input.length()) {
				ch = charAt(input, ++pos);
			}
			if (ch.isNumeric()) {
				while (ch != '' &&
				       (ch.isNumeric() || ch == '.'
				        || ch == 'e' || ch == 'E'
				        || (ch == '-' && token.length() > 0
				            && ('e' == charAt(token, token.length() - 1) || 'E' == charAt(token, token.length() - 1)))
				        || (ch == '+' && token.length() > 0
				            && ('e' == charAt(token, token.length() - 1) || 'E' == charAt(token, token.length() - 1)))
				       ) && (pos < input.length())) {
					token += charAt(input, pos++);
					ch = pos == input.length() ? '' : charAt(input, pos);
				}
			}
			else if (ch == '-'
			         && peekNextChar().isNumeric()
			         && ('('.equals(previousToken) || ','.equals(previousToken)
			             || previousToken == null || operators
			             .containsKey(previousToken))) {
				token += '-';
				pos++;
				token += next();
			}
			else if (ch.isAlpha() || (ch == '_')) {
				while (ch != '' && (ch.isAlpha() || ch.isNumeric() || (ch == '_')) && (pos < input.length())) {
					token += charAt(input, pos++);
					ch = pos == input.length() ? '' : charAt(input, pos);
				}
			}
			else if (ch == '(' || ch == ')' || ch == ',') {
				token += ch;
				pos++;
			}
			else {
				while (ch != '' && !ch.isAlpha() && !ch.isNumeric()
				       && ch != '_' && !ch.isWhitespace()
				       && ch != '(' && ch != ')' && ch != ','
				       && (pos < input.length())) {
					token += charAt(input, pos);
					pos++;
					ch = pos == input.length() ? '' : charAt(input, pos);
					if (ch == '-') {
						break;
					}
				}
				if (!operators.containsKey(token)) {
					throw new ExpressionException('Unknown operator \'' + token + '\' at position ' + (pos - token.length() + 1));
				}
			}
			return previousToken = token;
		}
		
		/**
		 * Get the actual character position in the string.
		 *
		 * @return the actual character position.
		 */
		public Integer getPos() {
			return pos;
		}
	}
	
	/**
	 * Expression assoc
	 */
	public enum Associability { LEFT, RIGHT }
	
	/**
	 * MathContext container
	 */
	public class MathContext {
		public Integer precision;
		public RoundingMode roundingMode;
		
		public MathContext(Integer precision, RoundingMode roundingMode) {
			this.precision = precision;
			this.roundingMode = roundingMode;
		}
	}
	
	public class AddOperator extends Operator {
		public AddOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return round(v1 + v2, mc);
		}
	}
	
	public class SubtractOperator extends Operator {
		public SubtractOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return round(v1 - v2, mc);
		}
	}
	
	public class MultiplyOperator extends Operator {
		public MultiplyOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return round(v1 * v2, mc);
		}
	}
	
	public class DivideOperator extends Operator {
		public DivideOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return v1.divide(v2, mc.precision, mc.roundingMode);
		}
	}
	
	public class ModOperator extends Operator {
		public ModOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			Decimal d = v1 - (v2 * (v1 / v2).intValue());
			return round(d, mc);
		}
	}
	
	public class PowOperator extends Operator {
		public PowOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return round(Decimal.valueOf(Math.pow(v1.doubleValue(), v2.doubleValue())), mc);
		}
	}
	
	public class AndOperator extends Operator {
		public AndOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			Boolean b1 = v1 != ZERO;
			Boolean b2 = v2 != ZERO;
			return b1 && b2 ? ONE : ZERO;
		}
	}
	
	public class OrOperator extends Operator {
		public OrOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			Boolean b1 = v1 != ZERO;
			Boolean b2 = v2 != ZERO;
			return b1 || b2 ? ONE : ZERO;
		}
	}
	
	public class GreaterOperator extends Operator {
		public GreaterOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return v1 > v2 ? ONE : ZERO;
		}
	}
	
	public class GreaterOrEqualOperator extends Operator {
		public GreaterOrEqualOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return v1 >= v2 ? ONE : ZERO;
		}
	}
	
	public class LessOperator extends Operator {
		public LessOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return v1 < v2 ? ONE : ZERO;
		}
	}
	
	public class LessEqualOperator extends Operator {
		public LessEqualOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return v1 <= v2 ? ONE : ZERO;
		}
	}
	
	public class EqualOperator extends Operator {
		public EqualOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return v1 == v2 ? ONE : ZERO;
		}
	}
	
	public class NotEqualOperator extends Operator {
		public NotEqualOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Decimal eval(Decimal v1, Decimal v2, MathContext mc) {
			return v1 != v2 ? ONE : ZERO;
		}
	}
	
	public class NotFunction extends Function {
		public NotFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('IF', numParams, parameters.size());
			Boolean isZero = parameters.get(0) == ZERO;
			return isZero ? ONE : ZERO;
		}
	}
	
	public class IfFunction extends Function {
		public IfFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('IF', numParams, parameters.size());
			Boolean isTrue = parameters.get(0) != ZERO;
			return isTrue ? parameters.get(1) : parameters.get(2);
		}
	}
	
	public class RandomFunction extends Function {
		public RandomFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('RANDOM', numParams, parameters.size());
			Decimal d = Decimal.valueOf(Math.random());
			return round(d, mc);
		}
	}
	
	public class SinFunction extends Function {
		public SinFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('SIN', numParams, parameters.size());
			Decimal d = Math.sin(toRadians(parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class CosFunction extends Function {
		public CosFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('COS', numParams, parameters.size());
			Decimal d = Math.cos(toRadians(parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class TanFunction extends Function {
		public TanFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('TAN', numParams, parameters.size());
			Decimal d = Math.tan(toRadians(parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class AsinFunction extends Function {
		public AsinFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('ASIN', numParams, parameters.size());
			Decimal d = toDegrees(Math.asin(parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class AcosFunction extends Function {
		public AcosFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('ACOS', numParams, parameters.size());
			Decimal d = toDegrees(Math.acos(parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class AtanFunction extends Function {
		public AtanFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('ATAN', numParams, parameters.size());
			Decimal d = toDegrees(Math.atan(parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class SinhFunction extends Function {
		public SinhFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('SINH', numParams, parameters.size());
			Decimal d = Math.sinh(parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class CoshFunction extends Function {
		public CoshFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('COSH', numParams, parameters.size());
			Decimal d = Math.cosh(parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class TanhFunction extends Function {
		public TanhFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('TANH', numParams, parameters.size());
			Decimal d = Math.tanh(parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class RadFunction extends Function {
		public RadFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('RAD', numParams, parameters.size());
			Decimal d = toRadians(parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class DegFunction extends Function {
		public DegFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('DEG', numParams, parameters.size());
			Decimal d = toDegrees(parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class MaxFunction extends Function {
		public MaxFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('MAX', numParams, parameters.size());
			Decimal max;
			for (Decimal parameter : parameters) {
				if (max == null || parameter > max) {
					max = parameter;
				}
			}
			return max;
		}
	}
	
	public class MinFunction extends Function {
		public MinFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('MIN', numParams, parameters.size());
			Decimal min;
			for (Decimal parameter : parameters) {
				if (min == null || parameter < min) {
					min = parameter;
				}
			}
			return min;
		}
	}
	
	public class AbsFunction extends Function {
		public AbsFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('ABS', numParams, parameters.size());
			return round(parameters.get(0).abs(), mc);
		}
	}
	
	public class LogFunction extends Function {
		public LogFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('LOG', numParams, parameters.size());
			Decimal d = Math.log(parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class Log10Function extends Function {
		public Log10Function(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('LOG10', numParams, parameters.size());
			Decimal d = Math.log10(parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class RoundFunction extends Function {
		public RoundFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('ROUND', numParams, parameters.size());
			Decimal d = parameters.get(0);
			Integer scale = parameters.get(1).intValue();
			return d.setScale(scale, mc.roundingMode);
		}
	}
	
	public class FloorFunction extends Function {
		public FloorFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('FLOOR', numParams, parameters.size());
			Decimal d = parameters.get(0);
			return d.setScale(0, RoundingMode.FLOOR);
		}
	}
	
	public class CeilingFunction extends Function {
		public CeilingFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('CEILING', numParams, parameters.size());
			Decimal d = parameters.get(0);
			return d.setScale(0, RoundingMode.CEILING);
		}
	}
	
	public class SqrtFunction extends Function {
		public SqrtFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Decimal eval(List<Decimal> parameters, MathContext mc) {
			verifyFunctionParams('SQRT', numParams, parameters.size());
			Decimal d = Math.sqrt(parameters.get(0));
			return round(d, mc);
		}
	}
	
	private static void verifyFunctionParams(String name, Integer expected, Integer actual) {
		String msg;
		if (expected == 0 && actual > 0) {
			msg = name + ' function does not take parameters';
		}
		else if (expected == -1 && actual == 0) {
			msg = name + ' function requires at least 1 parameter';
		}
		else if (expected != -1 && expected != actual) {
			msg = name + ' function requires ' + expected + ' parameter, got ' + actual;
		}
		if (msg != null) {
			throw new ExpressionException(msg);
		}
	}
	
	/**
	 * Expression evaluator exceptions
	 */
	public class ExpressionException extends Exception {}
	
	/**
	 * UnsupportedOperationException
	 */
	public class UnsupportedOperationException extends Exception {}
}
