require "ast"
RSpec.describe Ast do
    describe "#substitute" do
        it 'x{x |-> y} -> y' do
            ast = mk_var('x')
            expect(ast.substitute('x', mk_var('y'))).to eq(mk_var('y'))
        end
        it 'z{x |-> y} -> z' do
            ast = mk_var('z')
            expect(ast.substitute('x', mk_var('y'))).to eq(mk_var('z'))
        end
        it '(λx.+(x, y)){y |-> z} -> λx.+(x, z)' do
            ast = mk_lambda('x', mk_bin_exp('+', mk_var('x'), mk_var('y')))
            expect(ast.substitute('y', mk_var('z'))).to eq(mk_lambda('x', mk_bin_exp('+', mk_var('x'), mk_var('z'))))
        end
        it '(λx.+(x, y)){x |-> z} -> λx.+(x, y)' do
            ast = mk_lambda('x', mk_bin_exp('+', mk_var('x'), mk_var('y')))
            expect(ast.substitute('x', mk_var('z'))).to eq(ast)
        end
        it 'true{x|->y} -> true' do
            ast = mk_atom('true')
            expect(ast.substitute('x', mk_var('y'))).to eq(ast)
        end
        it '1{x|->y} -> 1' do
            ast = mk_nat(1)
            expect(ast.substitute('x', mk_var('y'))).to eq(ast)
        end
        it '1st(pair(x, 2)) {x |-> y} -> 1st(pair(y, 2))' do
            ast = mk_pair_builtin('1st', mk_pair(mk_var('x'), mk_nat(2)))
            expect(ast.substitute('x', mk_var('y'))).to eq(mk_pair_builtin('1st', mk_pair(mk_var('y'), mk_nat(2))))
        end
        it 'if(x, 1, 2) {x|->true} -> if(true, 1, 2)' do
            ast = mk_if(mk_var('x'), mk_nat(1), mk_nat(2))
            expect(ast.substitute('x', mk_atom('true'))).to eq(mk_if(mk_atom('true'), mk_nat(1), mk_nat(2)))
        end
        it '(letrec x = +(y, z) in x){x|->a} -> letrec x = +(y, z) in x' do
            ast = mk_letrec('x', mk_bin_exp('+', mk_var('y'), mk_var('z')), mk_var('x'))
            expect(ast.substitute('x', mk_var('a'))).to eq(ast)
        end
        it '(letrec x = +(y, z) in y){y|->a} -> letrec x = +(a, z) in a' do
            ast = mk_letrec('x', mk_bin_exp('+', mk_var('y'), mk_var('z')), mk_var('y'))
            expect(ast.substitute('y', mk_var('a'))).to eq(mk_letrec('x', mk_bin_exp('+', mk_var('a'), mk_var('z')), mk_var('a')))
        end
        it 'send(x, b) {x|->y} -> send(y, b)' do
            ast = mk_send(mk_var('x'), mk_var('b'))
            expect(ast.substitute('x', mk_var('y'))).to eq(mk_send(mk_var('y'), mk_var('b')))
        end
        it 'recv(x) {x|->y} -> recv(y)' do
            ast = mk_recv(mk_var('x'))
            expect(ast.substitute('x', mk_var('y'))).to eq(mk_recv(mk_var('y')))
        end
        it 'new(x) {x|->y} -> new(y)' do
            ast = mk_new(mk_var('x'))
            expect(ast.substitute('x', mk_var('y'))).to eq(mk_new(mk_var('y')))
        end
        it 'x(x) {x|->y} -> y(y)' do
            ast = mk_app(mk_var('x'), mk_var('x'))
            expect(ast.substitute('x', mk_var('y'))).to eq(mk_app(mk_var('y'), mk_var('y')))
        end
    end
end
