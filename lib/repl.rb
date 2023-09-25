require 'readline'
require 'colorize'
require 'optparse'
require_relative 'actor_parser'
require_relative 'actor_evaluator'

trace = false

opt = OptionParser.new
opt.on('--trace') {|v| trace = true }
opt.parse!(ARGV)

parser = Parser.new

while (line = Readline.readline('> ', true))
  break if line == 'exit'

  begin
    ast = parser.parse(line).ast
    until ast.val?
      ast = reduce(ast)
      puts ("--> " + ast.to_s).colorize(:blue) if trace and not ast.val?
    end

    puts ast.to_s
  rescue
    puts ("ERROR: " + $!.message).colorize(:red)
  end
end
