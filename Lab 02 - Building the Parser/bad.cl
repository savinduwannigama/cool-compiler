
(*
 *  execute "coolc bad.cl" to see the error messages that the coolc parser
 *  generates
 *
 *  execute "myparser bad.cl" to see the error messages that your parser
 *  generates
 *)

(* no error *)
class A {
};

(* error:  b is not a type identifier *)
Class b inherits A {
};

(* error:  a is not a type identifier *)
Class C inherits a {
};

(* error:  keyword inherits is misspelled *)
Class D inherts A {
};

(* error:  super class is missing *)
Class F inherits {
};

Class G inherits A {
    (* error: invalid type *)
    attr1 : int;
    
    (* error: method declaration without specifying the type *)
    method1() { };

    method2() : Int {
        {
            (* error: invalid symbol '^' in expression *)
            attr1 <- 2^3 - 1;
            attr1 <- attr1 + 1;
            (* error: two subsequent pluses *)
            attr1++;
        }
    };

    isPalindrome(s : String, j : Int) : Bool {
        if s.length() = 0
        then true
        else if s.length() = 1
        then true
        else if s.substr(0, 1) = s.substr(s.length() - 1, 1)
        then isPalindrome(s.substr(1, s.length() -2))
        else false
        fi fi fi
    };

    method3() : Bool {
        (* error: no comma separating the list of formals *)
        isPalindrome("racecar" attr1)
    };

    method4() : Int {
        (
            let x:Int <- 1 in
                (
                    let y:Int <- 2 in
                        (
                            (* errors: int, '=' *)
                            let z:Int <- 3, w:Int <- 4, k:int <- 5, j:Int = 6 in
                                (
                                    let v:Int <- 5 in x + y + z + w
                                )
                        )
                )
        ) + 5
    }
};

(* error:  closing brace is missing *)
Class E inherits A {
;
