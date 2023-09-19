require 'treetop'
Treetop.load 'lib/arith'

def parse(str)
  parser = ArithParser.new
  parser.parse(str)
end
