@isTest class RT_StackTest {

	@isTest static void testNewStackIsEmpty() {
		RT_Stack s = new RT_Stack();
		System.assert(s.empty());
		System.assertEquals(0, s.size());
	}
	
	@isTest static void testPushesToEmptyStack() {
		RT_Stack s = new RT_Stack();
		Integer numberOfPushes = 6;
		Object o;
		for (Integer i = 0; i < numberOfPushes; i++) {
			System.assertEquals(o = 'foo', s.push(o));
		}
		System.assertEquals(false, s.empty());
		System.assertEquals(numberOfPushes, s.size());
	}
	
	@isTest static void testPushThenPop() {
		RT_Stack s = new RT_Stack();
		Object o = 'foo';
		System.assertEquals(o, s.push(o));
		System.assertEquals(o, s.pop());
	}
	
	@isTest static void testPushThenPeek() {
		RT_Stack s = new RT_Stack();
		Object o = 'foo';
		System.assertEquals(o, s.push(o));
		Integer size = s.size();
		System.assertEquals(o, s.peek());
		System.assertEquals(size, s.size());
	}
	
	@isTest static void testPopToEmpty() {
		RT_Stack s = new RT_Stack();
		Integer numberOfPushes = (Integer)(Math.random() * 20 + 1);
		Object o;
		for (Integer i = 0; i < numberOfPushes; i++) {
			System.assertEquals(o = 'foo', s.push(o));
		}
		for (Integer i = 0; i < numberOfPushes; i++) {
			System.assertEquals('foo', s.pop());
		}
		System.assert(s.empty());
		System.assertEquals(0, s.size());
	}
	
	@isTest static void testPopEmptyStackThrows() {
		RT_Stack s = new RT_Stack();
		try {
			s.pop();
			System.assert(false);
		}
		catch (RT_Stack.EmptyStackException e) {}
	}
	
	@isTest static void testPeekEmptyStackThrows() {
		RT_Stack s = new RT_Stack();
		try {
			s.peek();
			System.assert(false);
		}
		catch (RT_Stack.EmptyStackException e) {}
	}
	
	@isTest static void testSearch() {
		RT_Stack s = new RT_Stack();
		s.push(null);
		s.push('foo');
		s.push('bar');
		s.push(null);
		s.push('foo');
		s.push('bar');
		System.assertEquals(6, s.size());
		System.assertEquals(1, s.search('bar'));
		System.assertEquals(2, s.search('foo'));
		System.assertEquals(3, s.search(null));
		System.assertEquals(-1, s.search('qux'));
	}
}