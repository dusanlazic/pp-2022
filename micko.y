%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
  #include "codegen.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  int out_lin = 0;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int foreach_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int lab_num = -1;
  int offset = 0;
  int array_idx = -1;
  int toggle_array[5]; // map for getting corresponding array/non-array types
  int force_array[5]; // map for getting array type from any type
  int ignore_array[5]; // map for getting non-array type from any type
  int is_array[5]; // map for determining if given type is array or non-array
  int num_of_elements = 0; // number of given elements when assigning values to an array
  int array_type = 0;
  int inside_foreach = 0;
  int iter_var_idx = -1;
  int iter_index_reg_idx = -1; // register for storing current index for iteration
  int iter_max_reg_idx = -1; // register for storing max index for iteration (array size - 1)
  // int iter_val_reg_idx = -1; // register for storing the value of the accessed element
  FILE *output;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token _FOREACH
%token _COLON
%token _CONTINUE
%token _BREAK
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACE
%token _RBRACE
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token _COMMA
%token <i> _AROP
%token <i> _RELOP

%type <i> num_exp exp literal
%type <i> function_call argument rel_exp if_part

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : 
      {
        // Type maps

        toggle_array[1] = 3; // INT        => INT_ARRAY
        toggle_array[3] = 1; // INT_ARRAY  => INT
        toggle_array[2] = 4; // UINT       => UINT_ARRAY
        toggle_array[4] = 2; // UINT_ARRAY => UINT 

        force_array[1] = 3; // INT        => INT_ARRAY
        force_array[3] = 3; // INT_ARRAY  => INT_ARRAY
        force_array[2] = 4; // UINT       => UINT_ARRAY
        force_array[4] = 4; // UINT_ARRAY => UINT_ARRAY 

        ignore_array[1] = 1; // INT        => INT
        ignore_array[3] = 1; // INT_ARRAY  => INT
        ignore_array[2] = 2; // UINT       => UINT
        ignore_array[4] = 2; // UINT_ARRAY => UINT 

        is_array[1] = 0;  // INT        => false
        is_array[2] = 0;  // UINT       => false
        is_array[3] = 1;  // INT_ARRAY  => true
        is_array[4] = 1;  // UINT_ARRAY => true 
      }
  function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
      }
  ;

function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
        else 
          err("redefinition of function '%s'", $2);

        code("\n%s:", $2);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN parameter _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        
        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  ;

parameter
  : /* empty */
      { set_atr1(fun_idx, 0); }

  | _TYPE _ID
      {
        insert_symbol($2, PAR, $1, 1, NO_ATR);
        set_atr1(fun_idx, 1);
        set_atr2(fun_idx, $1);
      }
  ;

body
  : _LBRACE variable_list
      {
        if(var_num)
          code("\n\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
        code("\n@%s_body:", get_name(fun_idx));
      }
    statement_list _RBRACE
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : _TYPE _ID _SEMICOLON
      {
        if(lookup_symbol($2, VAR|PAR) == NO_INDEX)
           insert_symbol($2, VAR, $1, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $2);
      }
  | _TYPE _ID _LBRACKET _INT_NUMBER _RBRACKET _SEMICOLON
      {
        if(lookup_symbol($2, VAR|PAR) == NO_INDEX) {
          insert_symbol($2, VAR, toggle_array[$1], ++var_num, atoi($4));
          var_num += atoi($4);
        }
      }
  ;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : compound_statement
  | assignment_statement
  | if_statement
  | return_statement
  | foreach_statement
  | break_statement
  | continue_statement
  ;

compound_statement
  : _LBRACE statement_list _RBRACE
  ;

assignment_statement

  // a = niz[0]; || a = 5; || ...
  : _ID _ASSIGN num_exp _SEMICOLON
      {
        int idx = lookup_symbol($1, VAR|PAR);
        if(idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(get_type(idx) != ignore_array[get_type($3)])
            err("incompatible types in assignment");
        
        if(is_array[get_type($3)])
          gen_mov_offset($3, idx, offset, 0);
        else
          gen_mov($3, idx);
      }

  // niz[0] = 5;
  | _ID _LBRACKET _INT_NUMBER _RBRACKET _ASSIGN num_exp _SEMICOLON // 
      {
        int idx = lookup_symbol($1, VAR|PAR);
        if (idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(ignore_array[get_type(idx)] != get_type($6))
            err("incompatible types in assignment");
        gen_mov_offset($6, idx, 0, atoi($3));
      }

  // niz = { 3, 1, 4, 1 };
  | _ID _ASSIGN
      {
        int idx = lookup_symbol($1, VAR|PAR);
        if (idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        
        array_type = ignore_array[get_type(idx)];
        array_idx = idx;
      }
    array _SEMICOLON
      {
        int arr_len = get_atr2(array_idx);

        if(arr_len != num_of_elements)
          err("array length is %d, %d elements given", arr_len, num_of_elements);
      }
    
  ;

array
  :
  { num_of_elements = 0; }
  _LBRACE array_values _RBRACE
  ;

array_values
  : literal
      { 
        if(get_type($1) != array_type) {
          err("invalid element type");
        }
        gen_mov_offset($1, array_idx, 0, num_of_elements);
        num_of_elements += 1;
      }
  | array_values _COMMA literal
      { 
        if(get_type($3) != array_type) {
          err("invalid element type");
        }
        gen_mov_offset($3, array_idx, 0, num_of_elements);
        num_of_elements += 1; 
      }
  ;

num_exp
  : exp

  | num_exp _AROP exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
        int t1 = get_type($1);    
        code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
        gen_sym_name($1);
        code(",");
        gen_sym_name($3);
        code(",");
        free_if_reg($3);
        free_if_reg($1);
        $$ = take_reg();
        gen_sym_name($$);
        set_type($$, t1);
      }
  ;

exp
  : literal

  | _ID
      {
        $$ = lookup_symbol($1, VAR|PAR);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
      }

  | function_call
      {
        $$ = take_reg();
        gen_mov(FUN_REG, $$);
      }
  
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }

  | _ID _LBRACKET _INT_NUMBER _RBRACKET
      {
        int idx = lookup_symbol($1, VAR|PAR);
        if (idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);

        int arr_len = get_atr2(idx);
        if(atoi($3) >= arr_len)
          err("index out of bounds: %d > %d", atoi($3), arr_len - 1);

        offset = atoi($3);
        $$ = idx;
      }
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' is not a function", $1);
      }
    _LPAREN argument _RPAREN
      {
        if(get_atr1(fcall_idx) != $4)
          err("wrong number of arguments");
        code("\n\t\t\tCALL\t%s", get_name(fcall_idx));
        if($4 > 0)
          code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
      }
  ;

argument
  : /* empty */
    { $$ = 0; }

  | num_exp
    { 
      if(get_atr2(fcall_idx) != get_type($1))
        err("incompatible type for argument");
      free_if_reg($1);
      code("\n\t\t\tPUSH\t");
      gen_sym_name($1);
      $$ = 1;
    }
  ;

if_statement
  : if_part %prec ONLY_IF
      { code("\n@exit%d:", $1); }

  | if_part _ELSE statement
      { code("\n@exit%d:", $1); }
  ;

if_part
  : _IF _LPAREN
      {
        $<i>$ = ++lab_num;
        code("\n@if%d:", lab_num);
      }
    rel_exp
      {
        code("\n\t\t%s\t@false%d", opp_jumps[$4], $<i>3);
        code("\n@true%d:", $<i>3);
      }
    _RPAREN statement
      {
        code("\n\t\tJMP \t@exit%d", $<i>3);
        code("\n@false%d:", $<i>3);
        $$ = $<i>3;
      }
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
        $$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER);
        gen_cmp($1, $3);
      }
  ;

return_statement
  : _RETURN num_exp _SEMICOLON
      {
        if(get_type(fun_idx) != ignore_array[get_type($2)])
          err("incompatible types in return");

        if(is_array[get_type($2)])
          gen_mov_offset($2, FUN_REG, offset, 0);
        else
          gen_mov($2, FUN_REG);
        
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));        
      }
  ;

foreach_statement
  : _FOREACH _LPAREN _TYPE _ID 
      {
        inside_foreach = 1;
        int temp = lookup_symbol($4, VAR|PAR);
        if (temp != NO_INDEX)
          err("redefinition of variable '%s'", $4);
      }
  _COLON _ID
      {
        int idx = lookup_symbol($7, VAR |PAR);
        if (idx == NO_INDEX)
          err("array '%s' is not defined", $7);
        else
          if($3 != ignore_array[get_type(idx)] ||
             get_type(idx) != force_array[$3])
            err("incompatible types in foreach statement");
          else {
            iter_var_idx = insert_symbol($4, VAR, $3, 1, NO_ATR);
            
            iter_index_reg_idx = take_reg();
            set_type(iter_index_reg_idx, INT);

            iter_max_reg_idx = take_reg();
            set_type(iter_max_reg_idx, INT);

            code("\n\t\tMOV \t$0,");
            gen_sym_name(iter_index_reg_idx);

            code("\n\t\tMOV \t$%d,", get_atr2(idx) - 1);
            gen_sym_name(iter_max_reg_idx);;

            code("\n@foreach%d:", ++foreach_num);
            code("\n\t\tADDS\t");
            gen_sym_name(iter_index_reg_idx);
            code(",$1,");
            gen_sym_name(iter_index_reg_idx);
          }
      }
  _RPAREN compound_statement
      {
        gen_cmp(iter_index_reg_idx, iter_max_reg_idx);
        code("\n\t\tJLES \t@foreach%d", foreach_num);
        code("\n@break%d:", foreach_num);
        clear_symbols(iter_var_idx);

        iter_var_idx = -1;
        
        inside_foreach = 0;
      }
  ;

break_statement
  :
    {
      if(!inside_foreach)
        err("break statement outside foreach");
      else
        code("\n\t\tJMP \t@break%d", foreach_num);
    }
  _BREAK _SEMICOLON
  ;

continue_statement
  :
    {
      if(!inside_foreach)
        err("continue statement outside foreach");
      else
        code("\n\t\tJMP \t@foreach%d", foreach_num);
    }
  _CONTINUE _SEMICOLON
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();
  output = fopen("output.asm", "w+");

  synerr = yyparse();

  clear_symtab();
  fclose(output);
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count) {
    remove("output.asm");
    printf("\n%d error(s).\n", error_count);
  }

  if(synerr)
    return -1;  //syntax error
  else if(error_count)
    return error_count & 127; //semantic errors
  else if(warning_count)
    return (warning_count & 127) + 127; //warnings
  else
    return 0; //OK
}

