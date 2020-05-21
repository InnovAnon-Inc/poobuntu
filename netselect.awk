BEGIN {
	print "_APTMGR=apt";
	print "DOWNLOADBEFORE=true"
	print "MIRRORS=( '"
}

{ printf "%s,", $2 }

END   {
	print "http://lmaddox.chickenkiller.com:3142' )\n"
}

