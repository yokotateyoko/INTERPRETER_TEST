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
    it '-(2, 1) -> 1' do
        ast = @parser.parse('-(2, 1)').ast
        expect(reduce(ast)).to eq(mk_nat(1))
    end
    it '-(2, 3) -> 0 : 引かれる数より引く数の方が大きければ 0' do
        ast = @parser.parse('-(2, 3)').ast
        expect(reduce(ast)).to eq(mk_nat(0))
    end
    it '-(2, -(1, 1)) -> -(2, 0)' do
        ast = @parser.parse('-(2, -(1,1))').ast
        expect(reduce(ast)).to eq(mk_bin_exp('-', mk_nat(2), mk_nat(0)))
    end
    it '*(3, 4) -> 12' do
        ast = @parser.parse('*(3, 4)').ast
        expect(reduce(ast)).to eq(mk_nat(12))
    end

    # 0除算は考えない！ /(4, 0) とかすると多分エラー出るけど気にしない
    it '/(4, 2) -> 2' do
        ast = @parser.parse('/(4, 2)').ast
        expect(reduce(ast)).to eq(mk_nat(2))
    end
    it '/(4, 3) -> 1' do
        ast = @parser.parse('/(4, 3)').ast
        expect(reduce(ast)).to eq(mk_nat(1))
    end
    it '=(4, 3) -> False' do
        ast = @parser.parse('=(4, 3)').ast
        expect(reduce(ast)).to eq(mk_atom('false'))
    end
    it '=(pair(1, 2), pair(1, 2)) -> True' do
        ast = @parser.parse('=(pair(1,2), pair(1,2))').ast
        expect(reduce(ast)).to eq(mk_atom('true'))
    end
    it '=(λx.x, 3) -> False' do
        ast = @parser.parse('=(λx.x, 3)').ast
        expect(reduce(ast)).to eq(mk_atom('false'))
    end

    it '1st(pair(1, 2)) -> 1' do
        ast = @parser.parse('1st(pair(1,2))').ast
        expect(reduce(ast)).to eq(mk_nat(1))
    end
    it '2nd(pair(1, 2)) -> 2' do
        ast = @parser.parse('2nd(pair(1,2))').ast
        expect(reduce(ast)).to eq(mk_nat(2))
    end

    it 'is_pair?(true) -> false' do
        ast = @parser.parse('is_pair?(true)').ast
        expect(reduce(ast)).to eq(mk_atom('false'))
    end
    it 'is_pair?(pair(2, 3)) -> true' do
        ast = @parser.parse('is_pair?(pair(2,3))').ast
        expect(reduce(ast)).to eq(mk_atom('true'))
    end
    it 'if(true, 1, 2) -> 1' do 
        ast = @parser.parse('if(true, 1, 2)').ast
        expect(reduce(ast)).to eq(mk_nat(1))
    end
    it 'if(false, 1, 2) -> 2' do 
        ast = @parser.parse('if(false, 1, 2)').ast
        expect(reduce(ast)).to eq(mk_nat(2))
    end
    it 'pair(+(1,1), 4) -> pair(2, 4)' do
        ast = @parser.parse('pair(+(1,1), 4)').ast
        expect(reduce(ast)).to eq(mk_pair(mk_nat(2), mk_nat(4)))
    end
    it 'pair(2, +(1,3)) -> pair(2, 4)' do
        ast = @parser.parse('pair(2, +(1,3))').ast
        expect(reduce(ast)).to eq(mk_pair(mk_nat(2), mk_nat(4)))
    end
    it '(λx.x)(1) -> 1' do
        ast = @parser.parse('(λx.x)(1)').ast
        expect(reduce(ast)).to eq(mk_nat(1))
    end
    it 'letrec x = 1 in x -> 1' do
        ast = @parser.parse('letrec x = 1 in x').ast
        expect(reduce(ast)).to eq(mk_nat(1))
    end
    it 'letrec fact = λx.if( =(x, 1), 1, *(x, fact(-(x,1))) ) in fact(4) -> 24' do
        ast = @parser.parse('letrec fact = λx.if( =(x, 1), 1, *(x, fact(-(x,1))) ) in fact(4)').ast
        # letrec fact = \x.if( =(x, 1), 1, *(x, fact(-(x,1))) ) in fact(4)
        until ast.val?
            ast = reduce(ast)
        end
        expect(ast).to eq(mk_nat(24))
    end
end