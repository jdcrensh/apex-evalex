@isTest class RT_StackTest {

	@isTest static void testNewStackIsEmpty() {
		RT_Stack s = new RT_Stack();
		System.assert(s.isEmpty());
		System.assertEquals(0, s.size());
	}

	@isTest static void testPushesToEmptyStack() {
		RT_Stack s = new RT_Stack();
		Integer numberOfPushes = 6;
		for (Integer i = 0; i < numberOfPushes; i++) {
			s.push('zzz');
		}
		System.assertEquals(false, s.isEmpty());
		System.assertEquals(numberOfPushes, s.size());
	}

	@isTest static void testPushThenPop() {
		RT_Stack s = new RT_Stack();
		String message = 'hello';
		s.push(message);
		System.assertEquals(message, s.pop());
	}

	@isTest static void testPushThenPeek() {
		RT_Stack s = new RT_Stack();
		String message = 'hello';
		s.push(message);
		Integer size = s.size();
		System.assertEquals(message, s.peek());
		System.assertEquals(size, s.size());
	}

	@isTest static void testPoppingDownToEmpty() {
		RT_Stack s = new RT_Stack();
		Integer numberOfPushes = (Integer)(Math.random() * 20 + 1);
		for (Integer i = 0; i < numberOfPushes; i++) {
			s.push('zzz');
		}
		for (Integer i = 0; i < numberOfPushes; i++) {
			s.pop();
		}
		System.assert(s.isEmpty());
		System.assertEquals(0, s.size());
	}

	@isTest static void testPopOnEmptyStack() {
		RT_Stack s = new RT_Stack();
		System.assert(s.isEmpty());
		try {
			s.pop();
			System.assert(false);
		}
		catch (Exception e) {}
	}

	@isTest static void testEmptyStackPeek() {
		RT_Stack s = new RT_Stack();
		System.assertEquals(null, s.peek());
	}
}