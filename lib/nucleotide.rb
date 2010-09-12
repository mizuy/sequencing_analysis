require 'bio'

class Regexp
  def each_match(str)
    start = 0
    while start < str.length
      m = match(str, start)
      return unless m
      yield m
      start = m.begin(0)+1
    end
  end
end

def search_primer(motif_seq, sequence)
  return [],[] if motif_seq.empty? or sequence.empty?
  seq_s = sequence.to_s
  def seq_to_re seq
    Regexp.new "(#{seq.to_re.to_s})"
  end
  reg = Regexp.union(seq_to_re(motif_seq), seq_to_re(motif_seq.reverse_complement))
  pp = []
  pc = []
  reg.each_match seq_s do |m|
    if m[1]
      pp << m.begin(0)
    end
    if m[2]
      pc << m.begin(0)
    end
  end
  return pp,pc
end

def bisulfite(seq, methyl)
  s = seq.to_s
  old = 'x'
  s.each_char.with_index do |c,i|
    if c=='c' and not (s[i+1]=='g' and methyl)
      s[i] = 't'
    end
  end
  Bio::Sequence::NA.new(s)
end

module Nucleotide

  class Primer
    attr_reader :name, :seq
    def initialize(name, seq)
      @name = name
      @seq = seq
    end
    def length
      @seq.length
    end
  end
  
  class PrimerPair
    attr_reader :fw, :rv
    def initialize(fw, rv)
      @fw = fw
      @rv = rv
    end
  end

  class PCRProduct
    attr_reader :fw, :rv, :seq, :startpos, :startpos_i, :endpos_i, :endpos, :template
    def initialize(template, startpos, endpos, fw, rv)
      @template = template
      @seq = template.seq.slice(startpos...endpos)
      @startpos = startpos
      @startpos_i = startpos + fw.length
      @endpos = endpos
      @endpos_i = endpos-rv.length
      @fw = fw
      @rv = rv
      @head = template.slice(@startpos...@startpos_i)
      @middle = template.slice(@startpos_i...@endpos_i)
      @tail = template.slice(@endpos_i...@endpos)
    end
    def length
      @seq.length
    end
    def cpg_sites
      (@startpos_i...@endpos_i).delete_if do |i|
        not (@seq[i]=='c' and @seq[i+1]=='g')
      end
    end
    def detectable_cpg
      cpg_sites.length
    end
  end      

  class PCR
    attr_reader :name, :template, :primers
    def initialize(name, template, fw, rv)
      @name = name
      @template = template
      @primers = PrimerPair.new(fw,rv)
      @products = nil
    end
    def fw
      @primers.fw
    end
    def rv
      @primers.rv
    end

    def products
      if not @products
        @products = _calc_products
      end
      @products
    end

    def combination(a0,a1)
      a0.each do |i|
        a1.each do |j|
          yield i,j
        end
      end
    end
    
    def _calc_products
      ret = []
      fpp,fpc = search_primer(fw,template)
      rpp,rpc = search_primer(rv,template)
      f = fpp+rpp
      r = fpc+rpc
      
      g = lambda{|f,r,i,j| PCRProduct.new(@template, i,j+r.length, f,r) }

      combination(fpp,fpc) { |i,j| next if i>j; ret << g.call(fw,fw,i,j) }
      combination(fpp,rpc) { |i,j| next if i>j; ret << g.call(fw,rv,i,j) }
      combination(rpp,rpc) { |i,j| next if i>j; ret << g.call(rw,fw,i,j) }
      combination(rpp,rpc) { |i,j| next if i>j; ret << g.call(rw,rw,i,j) }
      ret
    end
    
    
  end
  
end
