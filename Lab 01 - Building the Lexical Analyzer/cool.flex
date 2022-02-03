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
int opened_comments = 0;
// To keep track of found string literals, integer literals and identifiers.
// This count is used as an index to the string (symbol) table to store their semantic values.
int str_count = 0;

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
 // Exclusive start condition for comments.
%x COMMENT
 // Exclusive start condition for string literals.
%x STRING_LITERAL
 // Exclusive start condition for erroneous string literals.
%x ERROR_STRING_LITERAL

/* Some of the declaration names used here are same as the ones in cool-parse.h */

/* Operators. */
DARROW              =>
LE                  <=
ASSIGN              <-
OTHER               [+\-*(){}/;:,\.@~=<]

DIGIT               [0-9]
INTEGER             {DIGIT}+

LOWERCASE           [a-z]
UPPERCASE           [A-Z]
IDENTIFIER          ({LOWERCASE}|{UPPERCASE}|{DIGIT}|_)

TYPEID              {UPPERCASE}{IDENTIFIER}*
OBJECTID            {LOWERCASE}{IDENTIFIER}*

/* Keywords: Case-insensitive. */
CLASS               (?i:class)
ELSE                (?i:else)
FI                  (?i:fi)
IF                  (?i:if)
IN                  (?i:in)
INHERITS            (?i:inherits)
LET                 (?i:let)
LOOP                (?i:loop)
POOL                (?i:pool)
THEN                (?i:then)
WHILE               (?i:while)
CASE                (?i:case)
ESAC                (?i:esac)
OF                  (?i:of)
NEW                 (?i:new)
ISVOID              (?i:isvoid)
NOT                 (?i:not)
/* For the boolean constants: true and false, the first letter must be lowercase. */
TRUE                t(?i:rue)
FALSE               f(?i:alse)

/* Comments. */
LINE_COMMENT        --.*
OPEN_COMMENT        \(\*
CLOSE_COMMENT       \*\)

/* Whitespaces. */
WHITESPACE          [ \f\r\t\v]+
NEWLINE             \n

/* Other Special Characters */
QUOTE               \"
ANY_CHARACTER       .
EOF                 <EOF>
ESCAPED_NEWLINE	 	\\\n
NULL_CHARS		  	(\0|\\\0)
ESCAPE_CHARS	   	\\[ntbf]
BAD_ESCAPE			\\.

%%

 /*************************************************************************************************************
  * Rules Section: The rules section of the flex input contains a series of rules of the form:
  *
  *   pattern   action
  * 
  * where the pattern must be unindented and the action must begin on the same line.
  *************************************************************************************************************/

 /* Increment the current line number when the scanner matches a newline character if it is either in INITIAL or COMMENT start condition. */
<INITIAL,COMMENT>{NEWLINE}                { curr_lineno++; }

 /* 
  * Nested Comments.
  *
  * Increment the number of opened comments when an opening comment token is found if the scanner is either in INITIAL or COMMENT start condition.
  * Then, activate the COMMENT start condition. 
  */
<INITIAL,COMMENT>{OPEN_COMMENT}  { opened_comments++; BEGIN(COMMENT); }
 /* If the scanner found a closing comment token while in the intial start condition, 
  * then the found token doesn't have a matching opening comment token.
  */
<INITIAL>{CLOSE_COMMENT} { 
	cool_yylval.error_msg = "Unmatched *)"; 
	return ERROR; 
}
<COMMENT>{
	/* If the scanner found a closing comment token while in the COMMENT start condition, 
	* then the found token has a matching opening comment token. Decrement the number of opened comments
	* if it is non-zero. If the number of opened comments is zero, then activate the INITIAL start condition.
	*/
	{CLOSE_COMMENT} { 
		if (opened_comments > 0) opened_comments--;
		if (opened_comments == 0) BEGIN(INITIAL);
	}
	/* Scanner reads the contents of a comment, should not perform any action. */
	{ANY_CHARACTER}          	{ }
	/* If the scanner finds a comment that remains open when EOF is encountered, return the ERROR token. */
	{EOF} { 
		cool_yylval.error_msg = "EOF in comment"; 
		BEGIN(INITIAL); 
		return ERROR; 
	}
}
 /* Rule to match single line comments. */
{LINE_COMMENT}                    	{ }

 /*
  *  The multiple-character operators.
  */
{DARROW}		                   	{ return DARROW; }
{LE}			                   	{ return LE; }
{ASSIGN}		                   	{ return ASSIGN; }
 /* The character array yytext has the recently matched character. */
{OTHER}		                       	{ return yytext[0]; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS}		                      	{ return CLASS; }
{ELSE}			                  	{ return ELSE; }
{FI}			                  	{ return FI; }
{IF}			                  	{ return IF; }
{IN}			                  	{ return IN; }
{INHERITS}		                  	{ return INHERITS; }
{LET}                             	{ return LET; }
{LOOP}                            	{ return LOOP; }
{POOL}                            	{ return POOL; }
{THEN}                            	{ return THEN; }
{WHILE}                           	{ return WHILE; }
{CASE}                            	{ return CASE; }
{ESAC}                            	{ return ESAC; }
{OF}                              	{ return OF; }
{NEW}                             	{ return NEW; }
{ISVOID}                          	{ return ISVOID; }
{NOT}                             	{ return NOT; }
 /* The semantic values of the boolean constants are set to true or false. */
{TRUE}                            	{ cool_yylval.boolean = true; return BOOL_CONST; }
{FALSE}                           	{ cool_yylval.boolean = false; return BOOL_CONST; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  *  If the scanner finds a quote while in the INITIAL start condition, then it should activate the STRING_LITERAL start condition.
  *  Initialize the string buffer to empty, and set the string buffer pointer to the beginning of the string buffer.
  */
<INITIAL>{QUOTE} { 
	BEGIN(STRING_LITERAL);
	string_buf[0] = '\0';
	string_buf_ptr = string_buf;
}
<STRING_LITERAL>{
	/* 
	* If the scanner finds a quote while in the STRING_LITERAL start condition, then it should deactivate the STRING_LITERAL start condition. 
	* (The scanner is at the end of a string literal.)
	* Create a new string entry with the scanned string literal and store it in the string table.
	* Return the token STR_CONST.
	*/
	{QUOTE} {
		*string_buf_ptr = '\0';
		/*
		* Defined in stringtab.cc:
		* StringEntry::StringEntry(char *s, int l, int i) : Entry(s,l,i) { }
		*/
		cool_yylval.symbol = new StringEntry(string_buf, string_buf_ptr - string_buf, str_count++);
		BEGIN(INITIAL);
		return STR_CONST;
	}
	/*
	 * If the scanner finds a null character while in the STRING_LITERAL start condition, 
	 * then it should deactivate the STRING_LITERAL start condition and return the ERROR token.
	 */
	{NULL_CHARS} {
		cool_yylval.error_msg = "String contains null character";
		// Reset the string buffer pointer
		*string_buf_ptr = '\0';
		BEGIN(ERROR_STRING_LITERAL);
		return ERROR;
	}
	/*
	* When the scanner finds an unescaped newline while in the STRING_LITERAL start condition,
	* it should deactivate the STRING_LITERAL start condition and return the ERROR token.
	*/
	{NEWLINE} {
		// Increment the current line number.
		curr_lineno++;
		BEGIN(INITIAL);
		cool_yylval.error_msg = "Unterminated string constant";
		// Reset the string buffer pointer.
		*string_buf_ptr = '\0';
		return ERROR;
	}
	/* Handle escape sequences */
	{ESCAPE_CHARS} {
		if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
			// Reset the string buffer pointer.
			*string_buf_ptr = '\0';
			cool_yylval.error_msg = "String constant too long";
			BEGIN(ERROR_STRING_LITERAL);
			return ERROR;
		}
		switch (yytext[1]) {
			case '\\': *string_buf_ptr++ = '\\'; break;
			case 'n': *string_buf_ptr++ = '\n'; break;
			case 't': *string_buf_ptr++ = '\t'; break;
			case 'b': *string_buf_ptr++ = '\b'; break;
			case 'f': *string_buf_ptr++ = '\f'; break;
		}
	}
	/*
	* When the scanner finds an escaped newline while in the STRING_LITERAL start condition,
	* it should increment the current line number.
	*/
	{ESCAPED_NEWLINE} {
		// Increment the current line number.
		curr_lineno++;
		*string_buf_ptr++ = '\n';
	}
	/*
	 * When the scanner encounters any other escape characters while in the STRING_LITERAL start condition,
	 * it should append the character (excluding the escape i.e. yytext[1]) to the string buffer and increment
	 * the string buffer pointer only if the string length is less than the maximum string length.
	 */
	{BAD_ESCAPE} {
		// String length exceeds the maximum string length.
		if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
			// Reset the string buffer pointer.
			*string_buf_ptr = '\0';
			cool_yylval.error_msg = "String constant too long";
			BEGIN(ERROR_STRING_LITERAL);
			return ERROR;
		}
		*string_buf_ptr++ = yytext[1];
	}
	/*
	* If the scanner encounters an EOF while in the STRING_LITERAL start condition,
	* it should deactivate the STRING_LITERAL start condition and return the ERROR token.
	*/
	{EOF} {
		cool_yylval.error_msg = "EOF in string constant";
		BEGIN(INITIAL);
		return ERROR;
	}
	/*
	* When the scanner reads any other character while in the STRING_LITERAL start condition,
	* it should append the character to the string buffer and increment the string buffer pointer only if
	* the string length is less than the maximum string length.
	* 
	* Return ERROR token appropriately.
	*/
	{ANY_CHARACTER} {
		// String length exceeds the maximum string length.
		if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
			// Reset the string buffer pointer.
			*string_buf_ptr = '\0';
			cool_yylval.error_msg = "String constant too long";
			BEGIN(ERROR_STRING_LITERAL);
			return ERROR;
		}
		*string_buf_ptr++ = yytext[0];
	}
}
<ERROR_STRING_LITERAL>{
	/*
	 * If the scanner is currently reading an erroneous string literal,
	 * when it encounters a newline or another quote, it should go back to the INITIAL start condition.
	 * Otherwise, do nothing.
	 */
	{NEWLINE} { BEGIN(INITIAL); }
	{QUOTE} { BEGIN(INITIAL); }
	{ANY_CHARACTER} { }
}

 /*
  * Type and Object identifiers.
  */
{TYPEID} {
	/*
	 * Defined in stringtab.cc:
	 * IdEntry::IdEntry(char *s, int l, int i) : Entry(s,l,i) { }
	 */
	cool_yylval.symbol = new IdEntry(yytext, MAX_STR_CONST, str_count++);
	return TYPEID; 
}
{OBJECTID} {
	cool_yylval.symbol = new IdEntry(yytext, MAX_STR_CONST, str_count++);
	return OBJECTID;
}

 /*
  *  The integer literals.
  *  The scanner should accept any sequence of digits.
  *  Create a new integer entry with the scanned integer and store it in the string table.
  *  The scanner should return the token INT_CONST.
  */
{INTEGER} {
	/*
	 * Defined in stringtab.cc:
	 * IntEntry::IntEntry(char *s, int l, int i) : Entry(s,l,i) { }
	 */
	cool_yylval.symbol = new IntEntry(yytext, MAX_STR_CONST, str_count++);
	return INT_CONST;
}

 /* Do nothing for whitespace characters. */
<INITIAL>{WHITESPACE} 			  	{ }

 /* Return ERROR token for any other invalid character. */
{ANY_CHARACTER}						{ cool_yylval.error_msg = yytext; return ERROR; }

%%
