require 'readline'
require 'colorize'
require 'optparse'
require_relative 'actor_parser'
require_relative 'actor_evaluator'
require_relative 'configuration'

$trace = false
mode = :lambda
AVAILABLE_MODE = %i{lambda actor}

opt = OptionParser.new
opt.on('--trace') {|v| $trace = true }
opt.on('--mode=MODE') do |v|
  mode = v.to_sym
  unless AVAILABLE_MODE.include?(mode)
    raise "unsupported mode #{mode} (only #{AVAILABLE_MODE})"
  end
end
opt.parse!(ARGV)

$parser = Parser.new
def parser
  $parser
end

def actor_mode
  actors = {}
  while (line = Readline.readline('input "<actor>: <expression>" or "run" > ', true))
    break if line == 'exit'

    if line == 'run'
      break
    end

    name, program = line.split(': ')

    begin
      raise "invalid actor name (#{name})" unless parser.valid_var?(name)
      ast = parser.parse(program).ast
      actors[name] = ast
    rescue
      puts ("ERROR: " + $!.message).colorize(:red)
    end
  end
  # run の時だけやる TODO
  ac = ActorConfiguration.new(actors, [])
  while ac.transitionable?
    ac.transition
    puts ac if $trace  
  end
b  puts ac
end

def lambda_mode
  while (line = Readline.readline('> ', true))
    break if line == 'exit'

    begin
      ast = parser.parse(line).ast
      until ast.val?
        ast = reduce(ast)
        puts ("--> " + ast.to_s).colorize(:blue) if $trace and not ast.val?
      end

      puts ast.to_s
    rescue
      puts ("ERROR: " + $!.message).colorize(:red)
    end
  end
end
case mode
when :lambda
  lambda_mode
when :actor
  actor_mode
end
