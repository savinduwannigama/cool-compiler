/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

// To keep track of the length of the current string literal.
int str_length = 0;

%}

/*************************************************************************************************************
 * Definitions Section: Contains declarations of simple name definitions to simplify the scanner specification, 
 * and declarations of start conditions.
 * 
 * Name definitions have the form:
 * 
 *   name definition
 * 
 * The definition can subsequently be referred to using ‘{name}’, which will expand to ‘(definition)’. 
 **************************************************************************************************************/

/* Some of the declaration names used here are same as the ones in cool-parse.h */

/*
 * Start conditions are declared in the definitions (first) section of the input using unindented lines beginning with either ‘%s’ or ‘%x’ 
 * followed by a list of names. The former declares inclusive start conditions, the latter exclusive start conditions. 
 * A start condition is activated using the BEGIN action. Until the next BEGIN action is executed, rules with the given start condition 
 * will be active and rules with other start conditions will be inactive. If the start condition is inclusive, 
 * then rules with no start conditions at all will also be active. If it is exclusive, then only rules qualified with the start condition will be active.
 * A set of rules contingent on the same exclusive start condition describe a scanner which is independent of any of the other rules in the flex input.
 * Because of this, exclusive start conditions make it easy to specify “mini-scanners” which scan portions of the input that are syntactically different
 * from the rest (e.g., comments).
 */
%x COMMENT
%x STRING_LITERAL
%x PAREN

/* Operators. */
DARROW              =>
LE                  <=
ASSIGN              <-

DIGIT               [0-9]
INTEGER             {DIGIT}+

LOWERCASE           [a-z]
UPPERCASE           [A-Z]
IDENTIFIER          [{LOWERCASE}{UPPERCASE}{DIGIT}_]

TYPEID              {UPPERCASE}{IDENTIFIER}*
OBJECTID            {LOWERCASE}{IDENTIFIER}*

/* Keywords: Case-insensitive. */
CLASS               (?:class)
ELSE                (?:else)
FI                  (?:fi)
IF                  (?:if)
IN                  (?:in)
INHERITS            (?:inherits)
LET                 (?:let)
LOOP                (?:loop)
POOL                (?:pool)
THEN                (?:then)
WHILE               (?:while)
CASE                (?:case)
ESAC                (?:esac)
OF                  (?:of)
NEW                 (?:new)
ISVOID              (?:isvoid)
NOT                 (?:not)
/* For the boolean constants: true and false, the first letter must be lowercase. */
TRUE                t(?:rue)
FALSE               f(?:alse)

/* Comments. */
LINE_COMMENT        --.*
OPEN_COMMENT        \(\*
CLOSE_COMMENT       \*\)

/* Whitespaces. */
WHITESPACE          [ \t\n\r]
NEWLINE             \n

%%

 /*************************************************************************************************************
  * Rules Section: The rules section of the flex input contains a series of rules of the form:
  *
  *   pattern   action
  * 
  * where the pattern must be unindented and the action must begin on the same line.
  *************************************************************************************************************/

 /*
  *  New Lines.
  */
<COMMENT>{NEWLINE}       { curr_lineno++; }

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{LE}			  { return (LE); }
{ASSIGN}		{ return (ASSIGN); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
