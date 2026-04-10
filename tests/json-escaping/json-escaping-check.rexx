/* Unit Test Runner: t-rexx */
context('Checking the Reverse function')

/* Unit tests */
check('reverses "hello"' 'Reverse("hello")',,
      'Reverse("hello")',, '=', 'olleh')

check('reversed "hello" is not "hello"' 'Reverse("hello")',,
      'Reverse("hello")',, '\=', 'hello')

