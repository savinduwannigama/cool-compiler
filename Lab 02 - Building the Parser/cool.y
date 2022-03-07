/*
*  cool.y
*              Parser definition for the COOL language.
*
*/

/* PROLOGUE SECTION
 *******************
 * May define types and variables used in the actions as well as preprocessor commands to define
 * macros used there. You need to declare the lexical analyzer yylex and the error printer yyerror
 * here, along with any other global identifiers used by the actions in the grammar rules.
 */
%{
#include <iostream>
#include "cool-tree.h"
#include "stringtab.h"
#include "utilities.h"

extern char *curr_filename;


/* Locations */
#define YYLTYPE int              // The type of locations
#define cool_yylloc curr_lineno  // Use the curr_lineno from the lexer for the location of tokens

/* Set before constructing a tree node to whatever you want the line number for the tree node to be */
extern int node_lineno;
	
	
#define YYLLOC_DEFAULT(Current, Rhs, N)         \
Current = Rhs[1];                             \
node_lineno = Current;


#define SET_NODELOC(Current)  \
node_lineno = Current;

/* IMPORTANT NOTE ON LINE NUMBERS
*********************************
* The above definitions and macros cause every terminal in your grammar to 
* have the line number supplied by the lexer. The only task you have to
* implement for line numbers to work correctly, is to use SET_NODELOC()
* before constructing any constructs from non-terminals in your grammar.
* Example: Consider you are matching on the following very restrictive 
* (fictional) construct that matches a plus between two integer constants. 
* (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):

plus_consts	: INT_CONST '+' INT_CONST 

* where INT_CONST is a terminal for an integer constant. Now, a correct
* action for this rule that attaches the correct line number to plus_const
* would look like the following:

plus_consts	: INT_CONST '+' INT_CONST 
{
	// Set the line number of the current non-terminal:
	// ***********************************************
	// You can access the line numbers of the i'th item with @i, just
	// like you acess the value of the i'th exporession with $i.
	//
	// Here, we choose the line number of the last INT_CONST (@3) as the
	// line number of the resulting expression (@$). You are free to pick
	// any reasonable line as the line number of non-terminals. If you 
	// omit the statement @$=..., bison has default rules for deciding which 
	// line number to use. Check the manual for details if you are interested.
	@$ = @3;
	
	
	// Observe that we call SET_NODELOC(@3); this will set the global variable
	// node_lineno to @3. Since the constructor call "plus" uses the value of 
	// this global, the plus node will now have the correct line number.
	SET_NODELOC(@3);
	
	// construct the result node:
	$$ = plus(int_const($1), int_const($3));
}

*/



void yyerror(char *s);        	/*  defined below; called for each parse error */
extern int yylex();           	/*  the entry point to the lexer  */

/************************************************************************/
/*                DONT CHANGE ANYTHING IN THIS SECTION                  */

Program ast_root;	      		/* the result of the parse  */
Classes parse_results;        	/* for use in semantic analysis */
int omerrs = 0;               	/* number of errors in lexing and parsing */
%}
/*********************** END OF PROLOGUE SECTION ***********************/


/* BISON DECLARATIONS SECTION
 ****************************
 * Declare the names of the terminal and nonterminal symbols, and may also describe
 * operator precedence and the data types of semantic values of various symbols.
 */
/* A union of all the types that can be the result of parsing actions. */
%union {
	Boolean boolean;
	Symbol symbol;
	Program program;
	Class_ class_;
	Classes classes;
	Feature feature;
	Features features;
	Formal formal;
	Formals formals;
	Case case_;
	Cases cases;
	Expression expression;
	Expressions expressions;
	char *error_msg;
}

/* 
Declare the terminals; a few have types for associated lexemes.
The token ERROR is never used in the parser; thus, it is a parse
error when the lexer returns it.

The integer following token declaration is the numeric constant used
to represent that token internally.  Typically, Bison generates these
on its own, but we give explicit numbers to prevent version parity
problems (bison 1.25 and earlier start at 258, later versions -- at
257)
*/
%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol>  STR_CONST 275 INT_CONST 276 
%token <boolean> BOOL_CONST 277
%token <symbol>  TYPEID 278 OBJECTID 279 
%token ASSIGN 280 NOT 281 LE 282 ERROR 283

/*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
/**************************************************************************/

/* Complete the nonterminal list below, giving a type for the semantic
value of each non terminal. (See section 3.6 in the bison 
documentation for details). */

/* Declare types for the grammar's non-terminals. */
// Some of the declared type identifiers are named as same as they appear in the COOL manual.
%type <program> program
%type <classes> class_list
%type <class_> class
%type <features> feature_list
%type <feature> feature
%type <formals> formal_list
%type <formal> formal
/*
 * expr_list_comma_sep represents a list of expressions separated by commas (used in method dispatches).
 * expr_list_semicolon_sep represents a list of expressions separated by semicolons (used in expression blocks).
 */
%type <expressions> expr_list_comma_sep expr_list_semicolon_sep
%type <expression> expr expr_let_body
%type <case_> case_
%type <cases> case_branch_list


/* Precedence declarations go here. */
// All the binary operators are left-associative except for the assignment operator.
// The three comparison operators do not associate.
%right ASSIGN
%left NOT
%nonassoc LE '<' '='
%left '+' '-'
%left '*' '/'
%precedence ISVOID
%precedence '~'
%precedence '.'

/***************** END OF BISON DECLARATIONS SECTION *******************/


/* GRAMMAR RULES SECTION
 ***********************
 * Grammar rules define how to construct each nonterminal symbol from its parts (productions).
 * 
 * Most of the productions implemented below follow the Figure 1 of the COOL manual (page 17).
 */
%%
/* 
Save the root of the abstract syntax tree in a global variable.
*/
program	: class_list 
		{ 
			@$ = @1;
			ast_root = program($1); 
		}
;

/* There can be a single class or several classes in the class list of the program. */
class_list : class ';'												/* Single class */
		{
			SET_NODELOC(@1);
			$$ = single_Classes($1);
			parse_results = $$; 
		}
		| class_list class ';'										/* Several classes */
		{
			SET_NODELOC(@2);
			$$ = append_Classes($1, single_Classes($2)); 
			parse_results = $$; 
		}
;

/* If no parent is specified, the class inherits from the Object class. */
class : CLASS TYPEID '{' feature_list '}'
		{
			SET_NODELOC(@1);
			// Constructor signature: class_(name, parent, fratures, filename)
			$$ = class_($2, idtable.add_string("Object"), $4, stringtable.add_string(curr_filename)); 
		}
		| CLASS TYPEID INHERITS TYPEID '{' feature_list '}'
		{
			SET_NODELOC(@1);
			$$ = class_($2, $4, $6, stringtable.add_string(curr_filename)); 
		}
;

/* Feature list may be empty (i.e. the optional feature list), but no empty features in list. */
feature_list : %empty
		{
			$$ = nil_Features();
		}
		| feature ';'												/* Single feature */
		{
			SET_NODELOC(@1);
			$$ = single_Features($1);
		}
		| feature_list feature ';'									/* Several features */
		{
			SET_NODELOC(@2);
			$$ = append_Features($1, single_Features($2));
		}
;

feature :  OBJECTID '(' formal_list ')' ':' TYPEID '{' expr '}'		/* A feature can be a method */
		{
			SET_NODELOC(@1);
			$$ = method($1, $3, $6, $8);
		}
		| OBJECTID ':' TYPEID										/* A feature can be an attribute declaration without initialization */
		{
			SET_NODELOC(@1);
			$$ = attr($1, $3, no_expr());
		}
		| OBJECTID ':' TYPEID ASSIGN expr							/* A feature can be an attribute declaration with initialization */
		{
			SET_NODELOC(@1);
			$$ = attr($1, $3, $5);
		}
;

formal_list : %empty												/* Empty formal list (when it is optional) */
		{
			$$ = nil_Formals();
		}
		| formal													/* Single formal */
		{
			SET_NODELOC(@1);
			$$ = single_Formals($1);
		}
		| formal_list ',' formal									/* Several formals */
		{
			SET_NODELOC(@3);
			$$ = append_Formals($1, single_Formals($3));
		}
;

formal : OBJECTID ':' TYPEID
		{
			SET_NODELOC(@1);
			$$ = formal($1, $3);
		}
;

expr_list_comma_sep : %empty										/* Empty expression list (when it is optional) */
		{
			$$ = nil_Expressions();
		}
		| expr														/* Single expression */
		{
			SET_NODELOC(@1);
			$$ = single_Expressions($1);
		}
		| expr_list_comma_sep ',' expr								/* Several expressions */
		{
			SET_NODELOC(@3);
			$$ = append_Expressions($1, single_Expressions($3));
		}
;

expr_list_semicolon_sep : expr ';'									/* Single expression */
		{
			SET_NODELOC(@1);
			$$ = single_Expressions($1);
		}
		| expr_list_semicolon_sep expr ';'							/* Several expressions */
		{
			SET_NODELOC(@2);
			$$ = append_Expressions($1, single_Expressions($2));
		}
;

expr : OBJECTID ASSIGN expr
		{
			SET_NODELOC(@1);
			$$ = assign($1, $3);
		}
		| expr '.' OBJECTID '(' expr_list_comma_sep ')'				/* Method dispatch */
		{
			SET_NODELOC(@1);
			$$ = dispatch($1, $3, $5);
		}
		| expr '@' TYPEID '.' OBJECTID '(' expr_list_comma_sep ')'	/* Static method dispatch */
		{
			SET_NODELOC(@1);
			$$ = static_dispatch($1, $3, $5, $7);
		}
		| OBJECTID '(' expr_list_comma_sep ')'						/* Constructor dispatch */
		{
			SET_NODELOC(@1);
			//
			// Add a string requires two steps. First, the list is searched; if the
			// string is found, a pointer to the existing Entry for that string is 
			// returned. If the string is not found, a new Entry is created and added
			// to the list.
			//
			$$ = dispatch(object(idtable.add_string("self")), $1, $3);
		}
		| IF expr THEN expr ELSE expr FI							/* If-then-else conditional */
		{
			SET_NODELOC(@1);
			$$ = cond($2, $4, $6);
		}
		| WHILE expr LOOP expr POOL									/* While loop */
		{
			SET_NODELOC(@1);
			$$ = loop($2, $4);
		}
		| '{' expr_list_semicolon_sep '}'							/* Block */
		{
			SET_NODELOC(@1);
			$$ = block($2);
		}
		| LET expr_let_body											/* Let expression */
		{
			SET_NODELOC(@1);
			$$ = $2;
		}
		| CASE expr OF case_branch_list ESAC						/* Case expression */
		{
			SET_NODELOC(@1);
			$$ = typcase($2, $4);
		}
		| NEW TYPEID												/* New expression */
		{
			SET_NODELOC(@1);
			$$ = new_($2);
		}
		| ISVOID expr												/* Isvoid expression */
		{
			SET_NODELOC(@1);
			$$ = isvoid($2);
		}
		| expr '+' expr												/* Addition */
		{
			SET_NODELOC(@1);
			$$ = plus($1, $3);
		}
		| expr '-' expr												/* Subtraction */
		{
			SET_NODELOC(@1);
			$$ = sub($1, $3);
		}
		| expr '*' expr												/* Multiplication */
		{
			SET_NODELOC(@1);
			$$ = mul($1, $3);
		}
		| expr '/' expr												/* Division */
		{
			SET_NODELOC(@1);
			$$ = divide($1, $3);
		}
		| '~' expr													/* Bitwise negation */
		{
			SET_NODELOC(@1);
			$$ = neg($2);
		}
		| expr '<' expr												/* Less than */
		{
			SET_NODELOC(@1);
			$$ = lt($1, $3);
		}
		| expr LE expr												/* Less than or equal to */
		{
			SET_NODELOC(@1);
			$$ = leq($1, $3);
		}
		| expr '=' expr												/* Equality */
		{
			SET_NODELOC(@1);
			$$ = eq($1, $3);
		}
		| NOT expr 													/* Bitwise complement */
		{
			SET_NODELOC(@1);
			$$ = comp($2);
		}
		| '(' expr ')'												/* Parenthesized expression */
		{
			SET_NODELOC(@1);
			$$ = $2;
		}
		| OBJECTID													/* Identifier */
		{
			SET_NODELOC(@1);
			$$ = object($1);
		}
		| INT_CONST													/* Integer constant */
		{
			SET_NODELOC(@1);
			$$ = int_const($1);
		}
		| STR_CONST 												/* String constant */
		{
			SET_NODELOC(@1);
			$$ = string_const($1);
		}
		| BOOL_CONST												/* Boolean constant */
		{
			SET_NODELOC(@1);
			$$ = bool_const($1);
		}
;

expr_let_body : OBJECTID ':' TYPEID IN expr							/* Single expression in let body expression list */
		{
			SET_NODELOC(@1);
			// Constructor signature: let(name, type, initialization, expression)
			$$ = let($1, $3, no_expr(), $5);
		}
		| OBJECTID ':' TYPEID ASSIGN expr IN expr 					/* Single expression with assignment in let body expression list */
		{
			SET_NODELOC(@1);
			$$ = let($1, $3, $5, $7);
		}
		| OBJECTID ':' TYPEID ',' expr_let_body						/* Several expressions in let body expression list */
		{
			SET_NODELOC(@1);
			$$ = let($1, $3, no_expr(), $5);
		}
		| OBJECTID ':' TYPEID ASSIGN expr ',' expr_let_body			/* Several expressions with assignment in let body expression list */
		{
			SET_NODELOC(@1);
			$$ = let($1, $3, $5, $7);
		}
;

case_branch_list : case_ ';'										/* Single case branch */
		{
			SET_NODELOC(@1);
			$$ = single_Cases($1);
		}
		| case_branch_list case_ ';'								/* Several case branches */
		{
			SET_NODELOC(@1);
			$$ = append_Cases($1, single_Cases($2));
		}
;

case_ : OBJECTID ':' TYPEID DARROW expr								/* Case branch */
		{
			SET_NODELOC(@1);
			$$ = branch($1, $3, $5);
		}
;


%%
/********************* END OF GRAMMAR RULES SECTION *********************/


/* EPILOGUE SECTION
 ******************
 * Epilogue can contain any code you want to use. Often the definitions of functions
 * declared in the prologue go here. In a simple program, all the rest of the program can go
 * here.
 */
/* This function is called automatically when Bison detects a parse error. */
void yyerror(char *s)
{
	extern int curr_lineno;
	
	cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
	<< s << " at or near ";
	print_cool_token(yychar);
	cerr << endl;
	omerrs++;
	
	if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
}
/************************ END OF EPILOGUE SECTION ***********************/
