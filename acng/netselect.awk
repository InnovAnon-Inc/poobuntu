#! /usr/bin/env fawk

BEGIN   {
          printf "%s", "'"
}

#NR == 1 { printf  "%s", $2 }
#NR != 1 { printf ",%s", $2 }
NR == 1 { printf  "%s", $0 }
NR != 1 { printf ",%s", $0 }

END     { print "'"        }

