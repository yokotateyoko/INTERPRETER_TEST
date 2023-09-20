require_relative 'actor_parser'
require_relative 'actor_evaluator'

def readline
    print '> '
    $stdin.gets.strip
end
parser = Parser.new
while line = readline
    break if line == 'exit'
    begin
        ast = parser.parse(line).ast
        until ast.val?
            ast = reduce(ast)
        end
        puts ast.to_s
    rescue
        puts "ERROR: " + $!.message
    end
end
