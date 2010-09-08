require 'bio'
require 'prettyprint_sequence'

require 'rubygems'
require 'builder'

module SequencingAnalysis
  private

  class Result
    def initialize(writer, target_seq)
      @out = writer
      @b = Builder::XmlMarkup.new :target=>@out
      @b.html{
        @b.body{
          @b.div("class"=>"target-seq"){
            @b.text! 'Target Sequence:'
            @b.br
            @b.text! "Length: #{target_seq.length}"
            @b.br
            PrettyPrintSequence::print_html_sequence(@out, target_seq)
          }
          yield self
        }
      }
    end
    def add_query(definition, sequence, output, &block)
      @b.div("class"=>"query"){
        @b.text! definition
        yield
      }
    end

    def add_hit(hit)
      @b.div("class"=>"hit"){
        @b.text1 "evalue = #{hit.evalue}"
        @b.br
        @b.text1 "overlap = #{hit.overlap}"
        @b.br
        @out.puts "range = #{hit.target_start}...#{hit.target_end}"
        @b.br
        PrettyPrintSequence::print_html_sequences(@out, [hit.target_seq, hit.al_cons, hit.query_seq])
      }
    end

    def add_alignment(sequences)
      PrettyPrintSequence::print_html_sequences(@out, sequences)
    end

  end

  class SeqStream
    def initialize(seq)
      @index = 0
      @seq = seq
    end
    def top
      @seq[@index].chr
    end
    def get
      @index += 1
      @seq[@index-1].chr
    end
    def finish
      @seq.length <= @index
    end
    def length
      @seq.length
    end
    private
    def u(v)
      v ? v.chr : '-'
    end
  end

  class SeqStreams
    attr_accessor :target, :query
    def initialize(target,query,from,to)
      @target = SeqStream.new(target)
      @query = SeqStream.new(query)
      @from = from
      @to = to
      raise unless from<=to
    end
    def length
      @seq.length
    end

    def between?(value)
      value.between?(@from,@to)
    end
  end

  class AlignedSeqs
    def initialize(num)
      @seqs = ['']*num
    end
    def add(seqs)
      v = seqs.map {|i|i.length}.max
      seqs.each.with_index do |seq,i|
        @seqs[i] += '-'*(v-seq.length)+seq
      end
    end
    def seqs
      @seqs
    end
  end

  public
  module_function

  def align_hits(target_seq, hits)
    hh = hits.map do |hit|
      len = hit.target_end-hit.target_start
      raise "len=#{len}" unless len>0
      SeqStreams.new(hit.target_seq[30..-1], hit.query_seq[30..-1], hit.target_start-1, hit.target_start-1+len)
    end

    as = AlignedSeqs.new(1+hh.length)
    
    target_seq.each_char.with_index do |x,index|
      qss = []
      hh.each do |ss|
        qs = ''
        if ss.between?(index)
          #puts "#{index} #{x} #{ss.target.top} #{ss.query.top}"
          while not ss.target.finish and ss.target.top =='-'
            ss.target.get
            qs += ss.query.get
          end
          
          raise "x=#{x} ss.target.top=#{ss.target.top}" unless x==ss.target.top
          
          ss.target.get
          qs += ss.query.get
        end
        qss += [qs]
      end
      as.add([x] + qss)
    end
    as.seqs
  end

  def align_sequence(target_file, query_fasta, output)
    puts target_file
    target_seq = Bio::FlatFile.auto(target_file, 'r').next_entry.to_seq.to_s
    # you can get latest version of fasta from http://www.ebi.ac.uk/Tools/fasta/index.html
    factory = Bio::Fasta.local('fasta36', target_file, '-m 10')

    SequencingAnalysis::Result.new(output, target_seq) do |out|
      
      ff = Bio::FlatFile.new(Bio::FastaFormat, query_fasta)
      allhits = []
      ff.each do |entry|
        puts 'searching...'+entry.definition
        report = factory.query(entry)
        out.add_query(entry.definition, entry.to_seq.to_s.upcase, factory.output) do 
          hits = report.hits.delete_if {|hit| hit.evalue>0.01}

          hits.each do |hit| 
            out.add_hit(hit)
          end

          allhits += hits
        end
      end

      seqs = align_hits(target_seq, allhits)
      out.add_alignment(seqs)
    end

  end
end

