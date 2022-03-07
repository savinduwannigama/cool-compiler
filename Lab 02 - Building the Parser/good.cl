class A inherits IO {
    ana(): Int {
        (let x:Int <- 1 in 2) + 3
    };

    precedenceTest(): Int {
        3 + 4 * 5 / 2 - 1       -- Expected result: 12
    };
};

Class BB__ inherits A {
    isPalindrome(s : String) : Bool {
        if s.length() = 0
        then true
        else if s.length() = 1
        then true
        else if s.substr(0, 1) = s.substr(s.length() - 1, 1)
        then isPalindrome(s.substr(1, s.length() -2))
        else false
        fi fi fi
    };
};

class Main inherits BB__ {
    res : Bool;

    main() : SELF_TYPE {
        {
            out_string("Hello, World!\n");
            out_int(self.ana());
            out_string("\nOperator precedence test: ");
            out_int(self.precedenceTest());
            out_string("\n");
            out_string("Is \"racecar\" a palindrome? ");
            res <- self.isPalindrome("racecar");
            if res
            then out_string("Yes\n")
            else out_string("No\n")
            fi;
        }
    };
};