require "treetop"
require_relative 'ast'
Treetop.load "lib/actor"

class Parser < ActorParser
    def parse(input, *rest)
        syntax_node = super(input, *rest)
        raise ArgumentError.new(self.failure_reason) if syntax_node.nil?
        syntax_node
    end

    def valid_var?(input)
        begin
            self.parse(input, root: :var)
            true
        rescue
            false
        end
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