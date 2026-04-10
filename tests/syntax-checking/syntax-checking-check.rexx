/* Unit Test Runner: t-rexx */
context('Checking the Cube function')

/* Test Options */
numeric digits 20

/* Unit tests */
check('result isn''t zero' 'Cube(5)',,
      'Cube(5)',, '\=', 0)

check('cubes a large number' 'Cube(50000)',,
      'Cube(50000)',, '=', 125000000000000)

