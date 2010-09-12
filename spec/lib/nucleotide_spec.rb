
require 'rspec'
require_relative '../../lib/nucleotide'
require 'bio'

describe Nucleotide do
  describe Regexp do
    describe 'each_match' do
      it 'should be' do
        /ATGC/.enum_for(:each_match,'ATGCATGC').to_a.size.should == 2
        /ATGC/.enum_for(:each_match,'CCGC').to_a.size.should == 0
        /ATGC/.enum_for(:each_match,'').to_a.size.should == 0
        /ATGC/.enum_for(:each_match,'ATGC'*100).to_a.size.should == 100
      end
    end
  end
  describe 'search_primer' do
    def ts(str)
      Bio::Sequence::NA.new(str)
    end
    it 'should return empty arrays for empty seq, motif' do 
      pp,pc = search_primer(ts(''),ts(''))
      pp.should == []
      pc.should == []
    end
    it 'should return empty arrays for empty primer' do
      pp,pc = search_primer(ts(''),ts('atgc'))
      pp.should == []
      pc.should == []
    end
    it 'should return empty arrays for empty seq' do
      pp,pc = search_primer(ts('atgccgga'),ts(''))
      pp.should == []
      pc.should == []
    end

    it 'should return 0 for seq==motif, motif.rc!=motif' do
      pp,pc = search_primer(ts('aaaatgc'),ts('aaaatgc'))
      pp.should == [0]
      pc.should == []
    end
    
    it 'should propery find fw sequences' do
      pp,pc = search_primer(ts('aatgcc'),ts('aatgcc'*3))
      pp.should == [0,6,12]
      pc.should == []
    end

    it 'should propery find rv sequences' do
      pp,pc = search_primer(ts('aatgcc'),ts('aatgcc'*3).reverse_complement)
      pp.should == []
      pc.should == [0,6,12]
    end

  end
end
