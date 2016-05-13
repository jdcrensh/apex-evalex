/**
 * The `Stack` class represents a last-in-first-out (LIFO) stack of
 * objects. When a stack is first created, it contains no items. The
 * usual `push` and `pop` operations are provided, as well as a method
 * to `peek` at the top item on the stack, a method to test for whether
 * the stack is `empty`, and a method to `search` the stack for an item
 * and discover how far it is from the top.
 */
public class RT_Stack implements IStack {

	public interface IStack {
	
		/**
		 * Pushes an item onto the top of this stack
		 *
		 * @param  item  the item to be pushed onto this stack
		 * @return  the item
		 */
		Object push(Object item);
		
		/**
		 * Removes the object at the top of this stack and returns that
		 * object as the value of this function
		 *
		 * @return  The object at the top of this stack
		 * @exception  EmptyStackException if this stack is empty.
		 */
		Object pop();
		
		/**
		 * Looks at the object at the top of this stack without removing it
		 * from the stack
		 *
		 * @return  the object at the top of this stack
		 * @exception  EmptyStackException if this stack is empty
		 */
		Object peek();
		
		/**
		 * Returns the number of components in this stack
		 *
		 * @return  the number of components in this stack
		 */
		Integer size();
		
		/**
		 * Tests if this stack is empty
		 *
		 * @return  `true` if and only if this stack contains
		 *          no items; `false` otherwise.
		 */
		Boolean empty();
		
		/**
		 * Returns the 1-based position where an object is on this stack.
		 * If the object `o` occurs as an item in this stack, this
		 * method returns the distance from the top of the stack of the
		 * occurrence nearest the top of the stack; the topmost item on the
		 * stack is considered to be at distance `1`. The `equals`
		 * method is used to compare `o` to the items in this stack.
		 *
		 * @param   o  the desired object.
		 * @return  the 1-based position from the top of the stack where
		 *          the object is located; the return value `-1` indicates
		 *          that the object is not on the stack.
		 */
		Integer search(Object o);
	}
	
	public class EmptyStackException extends Exception {}
	
	private List<Object> stack;
	private Integer elementCount;
	
	/**
	 * Creates a pre-populated stack
	 *
	 * @param  stack  starting elements
	 */
	public RT_Stack(List<Object> stack) {
		this.stack = stack;
		elementCount = 0;
	}
	
	/**
	 * Creates an empty Stack.
	 */
	public RT_Stack() {
		this(new List<Object>());
	}
	
	public Object push(Object item) {
		stack.add(item);
		elementCount++;
		return item;
	}
	
	public Object pop() {
		if (elementCount == 0) {
			throw new EmptyStackException();
		}
		Object o = peek();
		stack.remove(--elementCount);
		return o;
	}
	
	public Object peek() {
		if (elementCount == 0) {
			throw new EmptyStackException();
		}
		return stack.get(stack.size() - 1);
	}
	
	public Integer size() {
		return elementCount;
	}
	
	public Boolean empty() {
		return elementCount == 0;
	}
	
	public Integer search(Object o) {
		Integer i = elementCount - 1;
		if (o == null) {
			while (i >= 0 && stack.get(i) != null) {
				i--;
			}
		}
		else {
			while (i >= 0 && !o.equals(stack.get(i))) {
				i--;
			}
		}
		return i >= 0 ? elementCount - i : -1;
	}
}