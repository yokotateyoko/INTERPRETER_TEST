require "treetop"
require_relative 'ast'
Treetop.load "lib/actor"

class Parser < ActorParser
    def parse(input)
        syntax_node = super(input)
        raise ArgumentError.new(self.failure_reason) if syntax_node.nil?
        syntax_node
    end
end
=begin
# 返り値: 成功時 AST 失敗時 エラー理由文字列
def parse(str)
    parser = ActorParser.new
    parse_result = parser.parse(str)
    parse_result.nil? ? parser.failure_reason : parse_result
end
=end