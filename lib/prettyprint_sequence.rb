require 'rubygems'
require 'builder'

module PrettyPrintSequence
  module_function

  def print_html_sequence(out, seq)
    b = Builder::XmlMarkup.new :target=>out
    b.pre {
      (0...seq.length).each_slice(100) do |line|
        b.span("class"=>"seq-index") {b.text! "#{sprintf '%04d', line[0]}: "}
        line.each_slice(10) do |block|
          block.each do |i|
            b.text! seq[i].chr
          end
          b.text! ' '
        end
        b.text! "\n"
      end
    }
  end

  def print_html_sequences(out, seqs, names=nil)
    if names
      raise unless names.length==seqs.length
    end
    num = seqs.length
    length = seqs.map{|x|x.length}.max
    b = Builder::XmlMarkup.new :target=>out
    b.pre{
      (0...length).each_slice(100) do |line|
        seqs.each.with_index do |seq,j|
          b.span("class"=>"seq-index") {b.text! "#{sprintf '%04d', line[0]}: "}
          line.each_slice(10) do |block|
            block.each do |i|
              c = seq[i]
              char = c ? c.chr : ' '
              if char=='N'
                b.span("style"=>"color:#f00;"){ b.text! "N" }
              else
                b.text! char
              end
            end
            b.text! ' '
          end
          b.text! "\n"
        end
        b.text! "\n"
      end
    }
  end

end
