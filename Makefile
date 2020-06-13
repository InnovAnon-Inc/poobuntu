.PHONY: all
all: poobuntu poobuntu-2004 poobuntu-1804 poobuntu-1604 \
     poodeb   poodeb-10     poodeb-9      poodeb-8

poodeb%: acng
	./run.sh
poobuntu%: acng
	./run.sh

acng: netselect
	$@/run.sh

%:
	$@/run.sh

#netselect:
#	cd netselect
#	./run.sh
#cksum:
#	cd cksum
#	./run.sh
#verify:
#	cd verify
#	./run.sh
