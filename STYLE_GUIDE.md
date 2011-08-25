Aji/Nowmov Style Guide
======================
*This is a collection of coding conventions both logical and semantic that I
think we should be following. I want to keep it in a file we can constantly
access, if we don't want it in the repo then we should have somewhere to put it
(that I can still edit in Vim.)*

## All Languages ##
- Indention is two spaces per block level. No tabs.
- There is no trailing whitespace. (It messes with paragraph navigation in Vim.)

## Ruby ##
These coding conventions are based on my own past and recent experience with the
Ruby programming language as well as observations of high quality code from the
likes of [John Nunemaker][JN], [Avdi Grimm][AG], [Peter Cooper][PC], and other
notable Ruby developers. Some of them are new and even things that I have not
hitherto subscribed to. They are however all wise, and thus we should reject
by way of our own discipline and observation new code which does not adhere
to these guidelines and endeavor to update previously written code whenever an
opportunity to do so arises.

- Parentheses are only used where absolutely necessary. This could also read as
  "Parentheses are only used where they increase readability and they only
  increase readability when the parser would fail without them."

- do-end block notation are used for mutliline blocks whereas braces are used
  for single line blocks.

-  Monkey patches to any class go in `lib/patches/$CLASS_NAME.rb`

- There is only one statement per line. (i.e. No semicolons in this codebase.)
  One line method definitions seem permissible at first but semicolons are
  uglier and less desirable than two extra lines of code. This also encourages
  us not to be afraid of growing a method in complexity when necessary.

- Multi-line chain statements should have '.' at the end of the line.

- Regarding orthogonality, two things are said "It is the pinnacle of software
  design" and "Orthogonality is pretentious". Ruby gives us an impressive
  capacity for keeping our software components isolated from each other while
  still allowing them to collaborate. Instead of coupling software through
  direct access to other components, consider using blocks and yielding to the
  caller to supply the interaction. This method decreases headaches in the
  future, especially when extending or refactoring software.

- Every bugfix and feature implementation should come with a corresponding test.

- Unit tests and model specs should test only the object or method under test
  and use mocks and stubs for all other components. If this style is found
  cumbersome it is indicative of too-tight coupling between software components
  and steps can probably be taken to fix this. Even if it means more objects,
  methods, and tests.

- Acceptance tests should test more than just the happy path. Ideally I would
  like to transition to Cucumber for acceptance tests because it will make it
  easier to logically separate implementation from application. But this will be
  a long and gradual task.

[JN]: http://github.com/jnunemaker
[AG]: http://avdi.org
[PC]: http://????


