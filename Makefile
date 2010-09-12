RUBY = ruby -I$(HOME)/projects/bioruby/lib -Ilib
all:
	$(RUBY) bin/align_sequencing example/construct/sequence.fasta example/construct/data/**/*.ab1 -o example/construct/output.html

view:
	$(RUBY) bin/seqview example/tp53.seqv
	open test.gif
#$(RUBY) bin/seqview example/ndrg2.gb

test:
	rspec

open:
	open example/construct/output.html

doc:
	rdoc lib

clean:
	rm -f **/#*#
	rm -f **/*~
