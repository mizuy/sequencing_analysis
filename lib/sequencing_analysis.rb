#!/usr/bin/env ruby -I/Users/mizuy/projects/bioruby/lib
require 'bio'

def min(a,b)
  a > b ? b : a
end

require 'prettyprint_sequence'

def print_abif(f)
  print f.atrace.length,f.ctrace.length,f.gtrace.length,f.ttrace.length
  puts f.peak_indices.length
  puts f.dye_mobility.length
  puts f.qualities.length
  puts f.chromatogram_type
  print 'sequence: ',f.sequence
  puts f.version
end

def read_fasta(f)
  ret = ''
  while line = f.gets
    if /^>.*$/ =~ line
      next
    else
      ret += line.chomp
    end
  end
  ret
end

def each_abif
  Dir.glob("data/*/*.ab1").each do |name|
    unless FileTest.directory?(name)
      yield name,Bio::Abif.open(name).next_entry
    end
  end
end

def emboss()
  f = File.open('sequence.txt','r')
  each_abif do |name,abif|
    puts name
    File.open('input.fasta','w') do |i|
      i.puts ">#{name}"
      i.puts abif.sequence
    end
    result = Bio::EMBOSS.run('water','-asequence','sequence.txt','-bsequence','input.fasta')
    puts result
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
    #print "#{@from} < #{value} < #{@to}\n"
    (@from <= value) and (value < @to)
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


def fasta(target)
  # you can get latest version of fasta from http://www.ebi.ac.uk/Tools/fasta/index.html
  factory = Bio::Fasta.local('fasta36', target, '-m 10')

  File.open('input.fasta','w') do |i|
    each_abif do |name,abif|
      i.puts ">#{File.basename name}"
      i.puts abif.sequence
    end
  end

  target_seq = read_fasta(File.open(target))
  out = File.open('output.html','w')
  out.print '<html><body>'
  out.print 'Target Sequence:<br />'
  out.print "Length: #{target_seq.length}<br />"
  print_html_sequence(out, target_seq)

  
  ff = Bio::FlatFile.new(Bio::FastaFormat, File.open('input.fasta','r'))
  allhits = []
  ff.each do |entry|
    out.print entry.definition
    out.print '<br/>'

    puts 'searching...'+entry.definition
    report = factory.query(entry)
    #puts factory.output

    hits = report.hits.delete_if {|hit| hit.evalue>0.01}

    hits.each do |hit|
      out.print "evalue = #{hit.evalue}<br/>"
      out.print "overlap = #{hit.overlap}<br/>"
      out.puts "range = #{hit.target_start}...#{hit.target_end}<br/>"
      print_html_sequences(out, [hit.target_seq, hit.al_cons, hit.query_seq])
    end

    puts report.list
    allhits += hits
  end

  hh = allhits.map do |hit|
    #puts "#{hit.target_start} - #{hit.target_end} :: #{hit.query_start} - #{hit.query_end}"
    #len = [hit.target_end-hit.target_start,(hit.query_end-hit.query_start).abs].min-30
    len = hit.target_end-hit.target_start
    raise "len=#{len}" unless len>0
    SeqStreams.new(hit.target_seq[30..-1], hit.query_seq[30..-1], hit.target_start-1, hit.target_start-1+len)
    #puts hit.target_seq, hit.target_start, len
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

  print_html_sequences(out, as.seqs)


  out.print '</body></html>'
end

fasta('sequence.txt')

