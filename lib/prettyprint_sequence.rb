def iterate(from, to, step=1)
  i = from
  while i<to
    yield i
    i += step
  end
end

def print_html_sequence(out, seq)
  out.print '<pre>'
  i = 0
  length = seq.length
  iterate(i, length, 100) do |i|
    out.print "<span class=\"seq-index\">#{sprintf '%04d', i}: </span>"
    iterate(i, [i+100, length].min, 10) do |ii|
      (ii...[ii+10, length].min).each do |iii|
        out.print seq[iii].chr
      end
      out.print ' '
    end
    out.print "\n"
  end
  out.print '</pre>'
end

def print_html_sequences(out, seqs, names=nil)
  if names
    raise unless names.length==seqs.length
  end
  num = seqs.length
  out.print '<pre>'
  length = seqs.map{|x|x.length}.max
  i = 0
  iterate(i, length, 100) do |i|
    (0...num).each do |j|
      out.print "<span class=\"seq-index\">#{sprintf '%04d', i}: </span>"
      iterate(i, [i+100, length].min, 10) do |ii|
        (ii...[ii+10, length].min).each do |iii|
          c = seqs[j][iii]
          char = c ? c.chr : ' '
          if char=='N'
            out.print "<span style=\"color:#f00;\">N</span>"
          else
            out.print char
          end
        end
        out.print ' '
      end
      out.print "\n"
    end
    out.print "\n"
  end
  out.print '</pre>'
end

