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
		Boolean evalBool();
		String toRPN();
		RT_Expression setPrecision(Integer precision);
		RT_Expression setRoundingMode(RoundingMode roundingMode);
		RT_Expression setVariable(String variable, Object value);
		RT_Expression with(String variable, Object value);
		Iterator<Token> getExpressionTokenizer();
		Set<String> getDeclaredVariables();
		Set<String> getDeclaredOperators();
		Set<String> getDeclaredFunctions();
	}
	
	public static final Decimal ZERO = 0, ONE = 1, MAX_INTEGER, MIN_INTEGER;
	
	/**
	 * All defined operators with name and implementation
	 */
	private static Map<String, Operator> operators;
	
	/**
	 * All defined operators with name and implementation
	 */
	private static Map<String, UnaryOperator> unaryOperators;
	
	/**
	 * All defined functions with name and implementation
	 */
	private static Map<String, Function> functions;
	
	/**
	 * Token types that are case-insensitive
	 */
	private static Set<TokenType> caseInsensitiveTokens;
	
	/**
	 * Default constants
	 */
	private static Map<String, Object> constants;
	
	static {
		MAX_INTEGER = Math.pow(2, 31).intValue();
		MIN_INTEGER = MAX_INTEGER + 1;
		
		operators = new Map<String, Operator>();
		unaryOperators = new Map<String, UnaryOperator>();
		functions = new Map<String, Function>();
		
		caseInsensitiveTokens = new Set<TokenType> {
			TokenType.VARIABLE,
			TokenType.FUNCTION
		};
		
		constants = new Map<String, Object> {
			'E' => Math.E,
			'PI' => Math.PI,
			'TRUE' => ONE,
			'FALSE' => ZERO,
			'NULL' => null
		};
		
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
		addOperator(new GreaterEqualOperator('>=', 10, Associability.RIGHT));
		addOperator(new LessOperator('<', 10, Associability.RIGHT));
		addOperator(new LessEqualOperator('<=', 10, Associability.RIGHT));
		addOperator(new EqualOperator('=', 7, Associability.RIGHT));
		addOperator(new EqualOperator('==', 7, Associability.RIGHT));
		addOperator(new NotEqualOperator('!=', 7, Associability.RIGHT));
		addOperator(new NotEqualOperator('<>', 7, Associability.RIGHT));
		
		// default unary operators
		addUnaryOperator(new PositiveOperator('+'));
		addUnaryOperator(new NegativeOperator('-'));
		
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
	 * Cached access to the RPN notation of this expression, ensures only one
	 * calculation of the RPN per expression instance. If no cached instance
	 * exists, a new one will be created and put to the cache.
	 *
	 * @return the cached RPN instance.
	 */
	private List<Token> rpn {
		get {
			if (rpn == null) {
				rpn = shuntingYard(this.expression);
				validate(rpn);
			}
			return rpn;
		}
		set;
	}
	
	/**
	 * All defined variables by name and value
	 */
	public Map<String, Object> variables;
	
	private Integer stringVarCount = 0;
	
	/**
	 * Creates a new expression instance from an expression string.
	 *
	 * @param expression the expression. E.g. `'2.4*sin(3)/(2-4)'` or `'sin(y)>0 & max(z, 3)>3'`
	 */
	public RT_Expression(String expression) {
		this(expression, new Map<String, Object>());
	}
	
	/**
	 * Creates a new expression instance from an expression string with the given variables.
	 *
	 * @param expression the expression. E.g. `'2.4*sin(3)/(2-4)'` or `'sin(y)>0 & max(z, 3)>3'`
	 * @param variables a mapping of variables
	 */
	public RT_Expression(String expression, Map<String, Object> variables) {
		this(expression, variables, new MathContext(7, RoundingMode.HALF_EVEN));
	}
	
	/**
	 * Creates a new expression instance from an expression string with a default MathContext.
	 *
	 * @param expression the expression. E.g. `'2.4*sin(3)/(2-4)'` or `'sin(y)>0 & max(z, 3)>3'`
	 * @param mc an instance of MathContext
	 */
	public RT_Expression(String expression, MathContext mc) {
		this(expression, new Map<String, Object>(), mc);
	}
	
	/**
	 * Creates a new expression instance from an expression string with the given variables
	 * and a default MathContext.
	 *
	 * @param expression the expression, eg: `2.4*sin(3)/(2-4)` or `sin(y)>0 && max(z, 3)>3`
	 * @param variables a mapping of variables
	 * @param mc an instance of MathContext
	 */
	public RT_Expression(String expression, Map<String, Object> variables, MathContext mc) {
		this.expression = expression;
		this.mc = mc;
		this.variables = new Map<String, Object>();
		for (String var : constants.keySet()) {
			setVariable(var, constants.get(var));
		}
		for (String var : variables.keySet()) {
			setVariable(var, variables.get(var));
		}
	}
	
	/**
	 * Implementation of the Shunting Yard algorithm to transform an
	 * infix expression to a RPN expression.
	 *
	 * @param expression the input expression in infx.
	 * @return an RPN representation of the expression, with each token as a list member.
	 */
	private List<Token> shuntingYard(String expression) {
		List<Token> outputQueue = new List<Token>();
		RT_Stack stack = new RT_Stack();
		
		Tokenizer tokenizer = new Tokenizer(expression, this);
		
		Token lastFunction;
		Token previousToken;
		while (tokenizer.hasNext()) {
			Token token = tokenizer.next();
			if (token.type == TokenType.NUMBERX || token.type == TokenType.VARIABLE) {
				outputQueue.add(token);
			}
			else if (token.type == TokenType.FUNCTION) {
				stack.push(token);
				lastFunction = token;
			}
			else if (token.type == TokenType.COMMA) {
				while (!stack.empty() && peekTokenType(stack) != TokenType.LEFT_PAREN) {
					outputQueue.add(popToken(stack));
				}
				if (stack.empty()) {
					throw new ExpressionException('Parse error for function \'' + (lastFunction == null ? null : lastFunction.text) + '\'');
				}
			}
			else if (token.type == TokenType.OPERATOR) {
				Operator o1 = operators.get(token.text);
				Token token2 = stack.empty() ? null : peekToken(stack);
				while (token2 != null && token2.type == TokenType.OPERATOR && isHigherPriority(o1, operators.get(token2.text))) {
					outputQueue.add(popToken(stack));
					token2 = stack.empty() ? null : peekToken(stack);
				}
				stack.push(token);
			}
			else if (token.type == TokenType.LEFT_PAREN) {
				if (previousToken != null) {
					if (previousToken.type == TokenType.NUMBERX) {
						throw new ExpressionException('Missing operator at character position ' + tokenizer.getPos());
					}
					// if the ( is preceded by a valid function, then it
					// denotes the start of a parameter list
					if (previousToken.type == TokenType.FUNCTION) {
						outputQueue.add(token);
					}
				}
				stack.push(token);
			}
			else if (token.type == TokenType.RIGHT_PAREN) {
				while (!stack.empty() && peekTokenType(stack) != TokenType.LEFT_PAREN) {
					outputQueue.add(popToken(stack));
				}
				if (stack.empty()) {
					throw new ExpressionException('Mismatched parentheses');
				}
				stack.pop();
				if (!stack.empty() && peekTokenType(stack) == TokenType.FUNCTION) {
					outputQueue.add(popToken(stack));
				}
			}
			previousToken = token;
		}
		while (!stack.empty()) {
			Token element = popToken(stack);
			if (element.type == TokenType.LEFT_PAREN || element.type == TokenType.RIGHT_PAREN) {
				throw new ExpressionException('Mismatched parentheses');
			}
			outputQueue.add(element);
		}
		return outputQueue;
	}
	
	private static Boolean isHigherPriority(Operator o1, Operator o2) {
		return o1.isLeftAssoc() && o1.getPrecedence() <= o2.getPrecedence() ||
		       o1.getPrecedence() < o2.getPrecedence();
	}
	
	private static Token peekToken(RT_Stack stack) {
		return (Token) stack.peek();
	}
	
	private static Token popToken(RT_Stack stack) {
		return (Token) stack.pop();
	}
	
	private static TokenType peekTokenType(RT_Stack stack) {
		return peekToken(stack).type;
	}
	
	/**
	 * Evaluates the expression.
	 *
	 * @return the result of the expression.
	 */
	public Decimal eval() {
		RT_Stack stack = new RT_Stack();
		
		for (Token token : rpn) {
			if (token.type == TokenType.OPERATOR) {
				Object v1 = stack.pop();
				Object v2 = stack.pop();
				if (v1 == null || isNumeric(v1)) {
					v1 = nullValue((Decimal) v1);
				}
				if (v2 == null || isNumeric(v2)) {
					v2 = nullValue((Decimal) v2);
				}
				Operator op = operators.get(token.text);
				stack.push(op.apply(v2, v1, this.mc));
			}
			else if (token.type == TokenType.UNDEFINED) {
				stack.push(0);
			}
			else if (token.type == TokenType.VARIABLE) {
				Object val = variables.get(token.text);
				if (val instanceof String && isNumber((String) val)) {
					val = Decimal.valueOf((String) val);
				}
				if (val instanceof String) {
					stack.push(val);
				}
				else {
					stack.push(round(nullValue((Decimal) val), mc));
				}
			}
			else if (token.type == TokenType.FUNCTION) {
				Function f = functions.get(token.text);
				List<Object> p = new List<Object>();
				// pop parameters off the stack until we hit the start of
				// this function's parameter list
				while (!stack.empty() && stack.peek() != null) {
					unshift(p, stack.pop());
				}
				if (stack.peek() == null) {
					stack.pop();
				}
				if (f.numParamsVaries() && p.isEmpty() || !f.numParamsVaries() && p.size() != f.getNumParams()) {
					throw new ExpressionException('Function ' + token.text + ' expected ' + f.getNumParams() + ' parameters, got ' + p.size());
				}
				
				stack.push(f.apply(p, this.mc));
			}
			else if (token.type == TokenType.LEFT_PAREN) {
				stack.push(null);
			}
			else {
				stack.push(Decimal.valueOf(token.text));
			}
		}
		
		Decimal res = stack.empty() ? 0 : (Decimal) stack.pop();
		return res.stripTrailingZeros();
	}
	
	public Boolean evalBool() {
		try {
			return eval() != 0;
		}
		catch (ExpressionException e) {
			if (e.getMessage() == 'Empty expression') {
				return true;
			}
			throw e;
		}
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
	 * Adds to the list of supported operators
	 *
	 * @param operator The operator to add
	 * @return the previous operator with that name, or `null` if there was none
	 */
	public static Operator addOperator(Operator operator) {
		return operators.put(operator.getOper(), operator);
	}
	
	/**
	 * Adds to the list of supported unary operators
	 *
	 * @param operator The operator to add
	 * @return the previous operator with that name, or `null` if there was none
	 */
	public static UnaryOperator addUnaryOperator(UnaryOperator operator) {
		return unaryOperators.put(operator.getOper(), operator);
	}
	
	/**
	 * Adds to the list of supported functions
	 *
	 * @param function The function to add
	 * @return the previous operator with that name, or `null` if there was none
	 */
	public static Function addFunction(Function function) {
		return functions.put(function.getName().toUpperCase(), function);
	}
	
	/**
	 * Sets a variable value.
	 *
	 * @param variable the variable to set
	 * @param value the variable value
	 * @return the expression for chaining
	 */
	public RT_Expression setVariable(String variable, Object value) {
		if (value instanceof Boolean) {
			value = (Boolean) value ? ONE : ZERO;
		}
		validateVariable(value);
		variables.put(variable.toUpperCase(), value);
		return this;// !a || !b => !(a && b)
	}
	
	/**
	 * Sets a variable value.
	 *
	 * @param variable The variable to set
	 * @param value The variable value
	 * @return the expression for chaining
	 */
	public RT_Expression with(String variable, Object value) {
		return setVariable(variable, value);
	}
	
	private void validateVariable(Object value) {
		if (value != null &&
		    !(isNumeric(value) ||
		      value instanceof Boolean ||
		      value instanceof String)) {
			throw new IllegalArgumentException('Object value \'' + value + '\' is not of a supported type');
		}
	}
	
	/**
	 * Get an iterator for this expression, allows iterating over an expression
	 * token by token.
	 *
	 * @return a new iterator instance for this expression.
	 */
	public Iterator<Token> getExpressionTokenizer() {
		return new Tokenizer(this.expression, this);
	}
	
	/**
	 * Check that the expression have enough numbers and variables to fit the
	 * requirements of the operators and functions, also check
	 * for only 1 result stored at the end of the evaluation.
	 *
	 */
	private void validate(List<Token> rpn) {
		/*-
		* Thanks to Norman Ramsey:
		* http://http://stackoverflow.com/questions/789847/postfix-notation-validation
		*/
		Integer counter = 0;
		RT_Stack params = new RT_Stack();
		for (Token token : rpn) {
			if (token.type == TokenType.LEFT_PAREN) {
				// is this a nested function call?
				if (!params.empty()) {
					// increment the current function's param count
					// (the return of the nested function call
					// will be a parameter for the current function)
					params.push((Integer) params.pop() + 1);
				}
				// start a new parameter count
				params.push(0);
			}
			else if (!params.empty()) {
				Integer inc = (Integer) params.pop() + 1;
				if (token.type == TokenType.FUNCTION) {
					// remove the parameters and the ( from the counter
					counter -= inc;
				}
				else {
					// increment the current function's param count
					params.push(inc);
				}
			}
			else if (token.type == TokenType.OPERATOR) {
				//we only have binary operators
				counter -= 2;
			}
			if (counter < 0) {
				throw new ExpressionException('Too many operators or functions at: ' + token.text);
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
		for (Token st : rpn) {
			if (result.length() != 0) {
				result += ' ';
			}
			result += st.text;
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
	
	private static Boolean isNumeric(Object o) {
		return o instanceof Decimal ||
		       o instanceof Double ||
		       o instanceof Integer ||
		       o instanceof Long;
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
		return nullValue(angdeg) / 180.0 * Math.PI;
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
		return nullValue(angrad) * 180.0 / Math.PI;
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
		d = nullValue(d);
		Integer precision = mc.precision;
		RoundingMode roundingMode = mc.roundingMode;
		Integer numToChop = d.precision() - precision;
		if (precision == 0 || numToChop <= 0) {
			return d;
		}
		Decimal div = Math.pow(10, Math.min(33 - precision, numToChop));
		Integer scale = Math.min(33, Math.max(-33, d.scale()));
		Decimal rounded = d.divide(div, scale, roundingMode);
		rounded = rounded * div;
		return rounded;
	}
	
	/**
	* Get value as zero in case of null
	* @param d Decimal that may be null
	* @return d if not null, zero otherwise
	*/
	private static Decimal nullValue(Decimal d) {
		return d == null ? ZERO : d;
	}
	
	/**
	 * Safely inserts an element at the beginning of a potentially empty list
	 */
	private static void unshift(List<Object> l, Object d) {
		if (l.isEmpty()) {
			l.add(d);
		}
		else {
			l.add(0, d);
		}
	}
	
	/**
	 * Exposing declared variables in the expression
	 * @return declared variables
	 */
	public Set<String> getDeclaredVariables() {
		return variables.keySet();
	}
	
	/**
	 * Returns a set of variable names referenced in the expression string
	 */
	public Set<String> getReferencedVariables() {
		Set<String> vars = new Set<String>();
		Tokenizer tokenizer = new Tokenizer(this.expression, this);
		while (tokenizer.hasNext()) {
			Token token = tokenizer.next();
			if (token.type == TokenType.VARIABLE || token.type == TokenType.UNDEFINED) {
				vars.add(token.text);
			}
		}
		return vars;
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
	
	public Boolean equals(Object obj) {
		if (obj === this) { return true; } // *NOPAD*
		if (obj == null) { return false; }
		if (!(obj instanceof RT_Expression)) { return false; }
		RT_Expression e = (RT_Expression) obj;
		if (expression != e.expression) { return false; }
		if (variables != e.variables) { return false; }
		return true;
	}
	
	public Integer hashCode() {
		Integer res = 1;
		res = 31 * res + (expression != null ? System.hashCode(expression) : 0);
		res = 31 * res + (variables != null ? System.hashCode(variables) : 0);
		return res;
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
		 * @param parameters passed by evaluator as a List of Object values
		 * @return a new Object value as a computing result
		 */
		public abstract Object apply(List<Object> parameters, MathContext mc);
	}
	
	/**
	 * Base definition of a supported operator
	 */
	public abstract class BaseOperator {
		/**
		 * This operators name (pattern).
		 */
		protected String oper;
		
		public String getOper() {
			return oper;
		}
	}
	
	/**
	 * Abstract definition of a supported operator. An operator is defined by
	 * its name (pattern), precedence, and if it is left or right associative.
	 */
	public abstract class Operator extends BaseOperator {
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
		public abstract Object apply(Object v1, Object v2, MathContext mc);
	}
	
	/**
	 * Abstract definition of a supported unary operator
	 */
	public abstract class UnaryOperator extends BaseOperator {
		/**
		 * Creates a new operator.
		 *
		 * @param oper operator name (pattern)
		 */
		public UnaryOperator(String oper) {
			this.oper = oper;
		}
		
		/**
		 * Implementation for this unary operator
		 *
		 * @param v operand
		 * @return result of the operation
		 */
		public abstract Object apply(Object v);
	}
	
	public class Token {
		public TokenType type;
		public String text;
		
		public Token(TokenType type, String text) {
			this.type = type;
			this.text = caseInsensitiveTokens.contains(type) ? text.toUpperCase() : text;
		}
	}
	
	public enum TokenType {
		OPERATOR,
		UNARY_OPERATOR,
		FUNCTION,
		VARIABLE,
		LEFT_PAREN,
		RIGHT_PAREN,
		COMMA,
		NUMBERX,
		UNDEFINED
	}
	
	/**
	 * Expression tokenizer that allows to iterate over a String
	 * expression token by token. Blank characters will be skipped.
	 */
	public class Tokenizer implements Iterator<Token> {
	
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
		private Token previousToken;
		
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
		
		public Token next() {
			String token = '';
			if (pos >= input.length()) {
				throw new IllegalStateException();
			}
			String ch = charAt(input, pos);
			while (ch.isWhitespace() && pos < input.length()) {
				ch = charAt(input, ++pos);
			}
			if (ch.isNumeric()) {
				while (
				    ch != '' && (
				        ch.isNumeric() || '.eE'.contains(ch) || (
				            token.length() > 0 &&
				            '+-'.contains(ch) &&
				            'e' == charAt(token, token.length() - 1)
				        )
				    ) && pos < input.length()
				) {
					token += charAt(input, pos++);
					ch = pos == input.length() ? '' : charAt(input, pos);
				}
				return previousToken = new Token(TokenType.NUMBERX, token);
			}
			else if (
			    unaryOperators.containsKey(ch) && (
			        peekNextChar().isNumeric() || peekNextChar() == '('
			    ) && (
			        previousToken == null ||
			        previousToken.type == TokenType.LEFT_PAREN ||
			        previousToken.type == TokenType.COMMA ||
			        previousToken.type == TokenType.OPERATOR
			    )
			) {
				token += ch;
				pos++;
				token += next().text;
				return previousToken = new Token(TokenType.NUMBERX, token);
			}
			else if ('\'"'.contains(ch)) {
				String ch2 = ++pos == input.length() ? '' : charAt(input, pos);
				while (ch != '' && ch != ch2 && pos < input.length()) {
					token += charAt(input, pos++);
					ch2 = pos == input.length() ? '' : charAt(input, pos);
				}
				if (ch == ch2) {
					pos++;
				}
				else {
					throw new ExpressionException('Parse error of string at position ' + (pos - token.length()));
				}
				String var = stringVariable(expr.stringVarCount++);
				expr.setVariable(var, token);
				return previousToken = new Token(TokenType.VARIABLE, var);
			}
			else if (ch == '_' || ch.isAlpha()) {
				while (ch != '' && (ch.isAlphaNumeric() || ch == '_' || ch == '.') && pos < input.length()) {
					token += charAt(input, pos++);
					ch = pos == input.length() ? '' : charAt(input, pos);
				}
				if (expr.variables.containsKey(token.toUpperCase())) {
					return previousToken = new Token(TokenType.VARIABLE, token);
				}
				else if (functions.containsKey(token.toUpperCase())) {
					return previousToken = new Token(TokenType.FUNCTION, token);
				}
				else if (ch != '(') {
					expr.setVariable(token, null);
					return previousToken = new Token(TokenType.VARIABLE, token);
				}
				throw new ExpressionException('Unknown function \'' + token + '\' at position ' + (pos - token.length() + 1));
			}
			else if (ch == '(') {
				pos++;
				return previousToken = new Token(TokenType.LEFT_PAREN, '(');
			}
			else if (ch == ')') {
				pos++;
				return previousToken = new Token(TokenType.RIGHT_PAREN, ')');
			}
			else if (ch == ',') {
				pos++;
				return previousToken = new Token(TokenType.COMMA, ',');
			}
			else {
				while (ch != '' && !ch.isAlphanumericSpace() && !'_(),"\''.contains(ch) && pos < input.length()) {
					token += charAt(input, pos++);
					ch = pos == input.length() ? '' : charAt(input, pos);
					if (unaryOperators.containsKey(ch)) {
						break;
					}
				}
				if (!operators.containsKey(token)) {
					throw new ExpressionException('Unknown operator \'' + token + '\' at position ' + (pos - token.length() + 1));
				}
				return previousToken = new Token(TokenType.OPERATOR, token);
			}
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
	
	private static String stringVariable(Integer i) {
		return '__STR' + i + '__';
	}
	
	/**
	 * Expression assoc
	 */
	public enum Associability {
		LEFT,
		RIGHT
	}
	
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
		public override Object apply(Object v1, Object v2, MathContext mc) {
			if (v1 instanceof String || v2 instanceof String) {
				return String.valueOf(v1) + String.valueOf(v2);
			}
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return round(d1 + d2, mc);
		}
	}
	
	public class SubtractOperator extends Operator {
		public SubtractOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return round(d1 - d2, mc);
		}
	}
	
	public class MultiplyOperator extends Operator {
		public MultiplyOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return round(d1 * d2, mc);
		}
	}
	
	public class DivideOperator extends Operator {
		public DivideOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return d1.divide(d2, mc.precision, mc.roundingMode);
		}
	}
	
	public class ModOperator extends Operator {
		public ModOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			Decimal d = d1 - (d2 * (d1 / d2).intValue());
			return round(d, mc);
		}
	}
	
	public class PowOperator extends Operator {
		public PowOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return round(Decimal.valueOf(Math.pow(d1.doubleValue(), d2.doubleValue())), mc);
		}
	}
	
	public class AndOperator extends Operator {
		public AndOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			Boolean b1 = v1 instanceof Boolean && (Boolean) v1 || v1 != ZERO;
			Boolean b2 = v2 instanceof Boolean && (Boolean) v2 || v2 != ZERO;
			return b1 && b2 ? ONE : ZERO;
		}
	}
	
	public class OrOperator extends Operator {
		public OrOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			Boolean b1 = v1 instanceof Boolean && (Boolean) v1 || v1 != ZERO;
			Boolean b2 = v2 instanceof Boolean && (Boolean) v2 || v2 != ZERO;
			return b1 || b2 ? ONE : ZERO;
		}
	}
	
	public class GreaterOperator extends Operator {
		public GreaterOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			if (v1 instanceof String || v2 instanceof String) {
				return String.valueOf(v1) > String.valueOf(v2) ? ONE : ZERO;
			}
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return d1 > d2 ? ONE : ZERO;
		}
	}
	
	public class GreaterEqualOperator extends Operator {
		public GreaterEqualOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			if (v1 instanceof String || v2 instanceof String) {
				return String.valueOf(v1) >= String.valueOf(v2) ? ONE : ZERO;
			}
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return d1 >= d2 ? ONE : ZERO;
		}
	}
	
	public class LessOperator extends Operator {
		public LessOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			if (v1 instanceof String || v2 instanceof String) {
				return String.valueOf(v1) < String.valueOf(v2) ? ONE : ZERO;
			}
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return d1 < d2 ? ONE : ZERO;
		}
	}
	
	public class LessEqualOperator extends Operator {
		public LessEqualOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			if (v1 instanceof String || v2 instanceof String) {
				return String.valueOf(v1) <= String.valueOf(v2) ? ONE : ZERO;
			}
			Decimal d1 = (Decimal) v1, d2 = (Decimal) v2;
			return d1 <= d2 ? ONE : ZERO;
		}
	}
	
	public class EqualOperator extends Operator {
		public EqualOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			return v1 == v2 ? ONE : ZERO;
		}
	}
	
	public class NotEqualOperator extends Operator {
		public NotEqualOperator(String oper, Integer precedence, Associability assoc) {
			super(oper, precedence, assoc);
		}
		public override Object apply(Object v1, Object v2, MathContext mc) {
			return v1 != v2 ? ONE : ZERO;
		}
	}
	
	public class PositiveOperator extends UnaryOperator {
		public PositiveOperator(String oper) {
			super(oper);
		}
		public override Object apply(Object v) {
			Decimal d = (Decimal) v;
			return +d;
		}
	}
	
	public class NegativeOperator extends UnaryOperator {
		public NegativeOperator(String oper) {
			super(oper);
		}
		public override Object apply(Object v) {
			Decimal d = (Decimal) v;
			return -d;
		}
	}
	
	public class NotFunction extends Function {
		public NotFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Boolean isZero = parameters.get(0) == ZERO;
			return isZero ? ONE : ZERO;
		}
	}
	
	public class IfFunction extends Function {
		public IfFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Boolean isTrue = parameters.get(0) != ZERO;
			return isTrue ? parameters.get(1) : parameters.get(2);
		}
	}
	
	public class RandomFunction extends Function {
		public RandomFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Decimal.valueOf(Math.random());
			return round(d, mc);
		}
	}
	
	public class SinFunction extends Function {
		public SinFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.sin(toRadians((Decimal) parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class CosFunction extends Function {
		public CosFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.cos(toRadians((Decimal) parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class TanFunction extends Function {
		public TanFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.tan(toRadians((Decimal) parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class AsinFunction extends Function {
		public AsinFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = toDegrees(Math.asin((Decimal) parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class AcosFunction extends Function {
		public AcosFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = toDegrees(Math.acos((Decimal) parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class AtanFunction extends Function {
		public AtanFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = toDegrees(Math.atan((Decimal) parameters.get(0)));
			return round(d, mc);
		}
	}
	
	public class SinhFunction extends Function {
		public SinhFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.sinh((Decimal) parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class CoshFunction extends Function {
		public CoshFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.cosh((Decimal) parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class TanhFunction extends Function {
		public TanhFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.tanh((Decimal) parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class RadFunction extends Function {
		public RadFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = toRadians((Decimal) parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class DegFunction extends Function {
		public DegFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = toDegrees((Decimal) parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class MaxFunction extends Function {
		public MaxFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal max;
			for (Object parameter : parameters) {
				Decimal d = (Decimal) parameter;
				if (max == null || d > max) {
					max = d;
				}
			}
			return max;
		}
	}
	
	public class MinFunction extends Function {
		public MinFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal min;
			for (Object parameter : parameters) {
				Decimal d = (Decimal) parameter;
				if (min == null || d < min) {
					min = d;
				}
			}
			return min;
		}
	}
	
	public class AbsFunction extends Function {
		public AbsFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = (Decimal) parameters.get(0);
			return round(d.abs(), mc);
		}
	}
	
	public class LogFunction extends Function {
		public LogFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.log((Decimal) parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class Log10Function extends Function {
		public Log10Function(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.log10((Decimal) parameters.get(0));
			return round(d, mc);
		}
	}
	
	public class RoundFunction extends Function {
		public RoundFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d1 = (Decimal) parameters.get(0);
			Decimal d2 = (Decimal) parameters.get(1);
			Integer scale = d2.intValue();
			return d1.setScale(scale, mc.roundingMode);
		}
	}
	
	public class FloorFunction extends Function {
		public FloorFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = (Decimal) parameters.get(0);
			return d.setScale(0, RoundingMode.FLOOR);
		}
	}
	
	public class CeilingFunction extends Function {
		public CeilingFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = (Decimal) parameters.get(0);
			return d.setScale(0, RoundingMode.CEILING);
		}
	}
	
	public class SqrtFunction extends Function {
		public SqrtFunction(String name, Integer numParams) {
			super(name, numParams);
		}
		public override Object apply(List<Object> parameters, MathContext mc) {
			Decimal d = Math.sqrt((Decimal) parameters.get(0));
			return round(d, mc);
		}
	}
	
	/**
	 * Expression evaluator exceptions
	 */
	public class ExpressionException extends Exception {}
	
	/**
	 * IllegalStateException
	 */
	public class IllegalStateException extends Exception {}
	
	/**
	 * IllegalArgumentException
	 */
	public class IllegalArgumentException extends Exception {}
}