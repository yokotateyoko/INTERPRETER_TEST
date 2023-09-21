require 'readline'
require_relative 'actor_parser'
require_relative 'actor_evaluator'

parser = Parser.new

while (line = Readline.readline('> ', true))
  break if line == 'exit'

  begin
    ast = parser.parse(line).ast
    ast = reduce(ast) until ast.val?

    puts ast.to_s
  rescue
    puts "ERROR: " + $!.message
  end
end
