A script for counting actual lines of code in a file.

Works for both line- and block-comments.

Nested comments are not implemented.

Assumes comments aren't placed haphazardly:
Lines containing a block comment start or end character are counted as comment lines.
example:
printf("Hello World!\n") /* comment comment comment
* comment */ printf("Hello World!\n");
is counted as 2 comment lines.
