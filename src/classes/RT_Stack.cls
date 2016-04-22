/**
 * Apex implementation of the stack data structure
 */
public class RT_Stack implements IStack {

	public interface IStack {
		void push(Object item);
		Object pop();
		Object peek();
		Integer size();
		Boolean isEmpty();
	}

	private List<Object> stack;

	public RT_Stack(List<Object> stack) {
		this.stack = stack;
	}

	public RT_Stack() {
		this(new List<Object>());
	}

	public void push(Object item) {
		stack.add(item);
	}

	public Object pop() {
		return stack.remove(stack.size() - 1);
	}

	public Object peek() {
		if (isEmpty()) {
			return null;
		}
		return stack.get(stack.size() - 1);
	}

	public Integer size() {
		return stack.size();
	}

	public Boolean isEmpty() {
		return stack.isEmpty();
	}
}
