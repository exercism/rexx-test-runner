Reverse : procedure
  text = ARG(1) ; result = ''
  do i = LENGTH(text) to 1 by -1 ; result = result || SUBSTR(text, i, 1) ; end
return result
