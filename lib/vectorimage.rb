require 'forwardable'

require 'rvg/rvg'
include Magick

RVG::dpi = 72

class VectorImageBody
  extend Forwardable
  def_delegators :@body, :line,:rect,:text

  attr_reader :width, :height
  def initialize(parent, x, y)
    @parent = parent
    @body = parent.group.g.translate(x,y)
    @trans_x = x
    @trans_y = y
  end

  def translate(x,y)
    r = VectorImageBody.new(self, x, y)
    yield r if block_given?
    r
  end

  def absolute
    @parent.absolute
  end

  def trans(x,y)
    @parent.trans x + @trans_x, y + @trans_y
  end

  def add_region(name, x0, y0, x1, y1)
    @parent.add_region(name, x0+@trans_x, y0+@trans_y, x1+@trans_x, y1+@trans_y)
  end

  def group
    @body.g
  end
end

class VectorImage
  attr_reader :width, :height
  def initialize(w,h,view_w,view_h,initx=0,inity=0)
    @initx = initx
    @inity = inity
    @width = w
    @height = h
    @view_w = view_w
    @view_h = view_h
    @regions = []
    @r = RVG.new(w.px, h.px).preserve_aspect_ratio('none','meet').viewbox(0,0,w,h)
    @r.background_fill = 'white'
    @abs = @r.g
    @rvg = @r.g.translate(initx,inity).scale((w.to_f)/view_w,(h.to_f)/view_h)
  end

  def translate(x,y)
    r = VectorImageBody.new(self, x, y)
    yield r if block_given?
    r
  end

  def absolute
    @abs.g
  end

  def group
    @rvg.g
  end

  def trans(x,y)
    [(x.to_f)/@view_w*@width+@initx, (y.to_f)/@view_h*@height+@inity]
  end

  def add_region(name,x0,y0,x1,y1)
    rx0, ry0 = trans x0, y0
    rx1, ry1 = trans x1, y1
    @regions << [name, rx0, ry0, rx1, ry1]
  end

  def each_region
    @regions.each do |v|
      name, x0, y0, x1, y1 = v
      yield name, x0, y0, x1, y1
    end
  end

  def write(filename)
    @r.draw.write(filename)
  end

end
