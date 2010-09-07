all:
	ruby -I$(HOME)/projects/bioruby/lib -Ilib bin/align_sequencing example/construct/sequence.fasta example/construct/data/**/*.ab1 -o example/construct/output.html

test:
	rspec

open:
	open example/construct/output.html

doc:
	rdoc lib
