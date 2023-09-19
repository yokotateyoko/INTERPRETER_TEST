require "actor_evaluator"
require "actor_parser"

RSpec.describe do
    before do
        @parser = Parser.new
    end

    it '+(1, 1) -> 2' do
        ast = @parser.parse('+(1, 1)').ast
        expect(reduce(ast)).to eq(mk_nat(2))
    end
    # R = +(1, ▫️)
    # +(1, ▫️) > +(1, 1) <
    it '+(1, +(1, 1)) -> +(1, 2)' do
        ast = @parser.parse('+(1, +(1,1))').ast
        expect(reduce(ast)).to eq(mk_bin_exp('+', mk_nat(1), mk_nat(2)))
    end
end
