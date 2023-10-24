require "actor_parser"
RSpec.describe do
    before do
        @parser = Parser.new
    end

    describe "Atom のパース" do
        atom = %w[ true false null]
        atom.each do |a|
            it a do
                expect(@parser.parse(a)).not_to be_nil
                expect(@parser.parse(a).ast).to eq(mk_atom(a))
            end
        end
    end
    describe "自然数のパース" do
        it "0" do
            expect(@parser.parse("0").ast).to eq(mk_nat(0))
        end
        it "123" do
            expect(@parser.parse("123").ast).to eq(mk_nat(123))
        end
    end
    describe "変数のパース" do
        it "小文字1文字のみを許容する" do
            expect(@parser.parse("x").ast).to eq(mk_var("x"))
        end
        it "アンダースコアを許容する" do
            expect(@parser.parse("box_height").ast).to eq(mk_var("box_height")) 
        end
        it "大文字、先頭以外の数字を許容する" do
            expect(@parser.parse("MIX123").ast).to eq(mk_var("MIX123"))
        end
        it "アンダースコア始まりを許容しない" do
            expect do @parser.parse("_MIX123") end.to raise_error(ArgumentError)
            # expect(@parser.parse("_MIX123")).to be_nil
        end
        it "数字から始まる変数名は許容しない" do
            expect do @parser.parse("123_variable") end.to raise_error(ArgumentError)
        end
    end
    describe "プリミティブ演算適用のパース" do
        ope = %w[+ - / * =]
        ope_name = %w[加算 減算 除算 掛け算 同値比較]
        ope.zip(ope_name).each do |op, name|
            it name do
                expect(@parser.parse("#{op}(1, 2)").ast).to eq(
                    mk_bin_exp(op, mk_nat(1), mk_nat(2))
                )
            end
            it "#{name} の引数の数が異なる" do
                expect do @parser.parse("#{op}(1)") end.to raise_error(ArgumentError)
            end
        end
        it "is_pair? 演算" do
            expect(@parser.parse("is_pair?(1)").ast).to eq(
                mk_pair_builtin('is_pair?', mk_nat(1))
            )
        end
        it "1st 演算" do
            expect(@parser.parse("1st(hoge)").ast).to eq(
                mk_pair_builtin('1st', mk_var('hoge'))
            )
        end
        it "2nd 演算" do
            expect(@parser.parse("2nd(fuga)").ast).to eq(
                mk_pair_builtin('2nd', mk_var('fuga'))
            )
        end
        it "is_pair? 演算の引数の数が異なる" do
            expect do @parser.parse("is_pair?(1,2)") end.to raise_error(ArgumentError)
        end
        it "1st 演算の引数の数が異なる" do
            expect do @parser.parse("1st(hoge,2)") end.to raise_error(ArgumentError)
        end
        it "2nd 演算の引数の数が異なる" do
            expect do @parser.parse("2nd(fuga,3)") end.to raise_error(ArgumentError)
        end
    end

    describe 'ラムダ抽象のパース' do
        plus_x5 = mk_bin_exp('+', mk_var('x'), mk_nat(5))
        it "ラムダ抽象" do
            expect(@parser.parse('\x.+(x,5)').ast).to eq(
               mk_lambda('x', plus_x5)
            )
        end
        it "カリー化された関数は許容する" do
            expect(@parser.parse('\x. \y. +(x,5)').ast).to eq(
                mk_lambda('x', mk_lambda('y', plus_x5))
            )
        end
        it "カリー化された関数は許容する (x + y版)" do
            plus_xy = mk_bin_exp('+', mk_var('x'), mk_var('y'))
            expect(@parser.parse('\x. \y. +(x,y)').ast).to eq(
                mk_lambda('x', mk_lambda('y', plus_xy))
            )
        end
        it "引数が複数あるのは NG" do
            expect do @parser.parse('\\x y.+(x,5)') end.to raise_error(ArgumentError)
        end
    end

    describe 'ペア生成のパース' do
        it 'value を引数に取るペア生成' do
            expect(@parser.parse("pair(1, x)").ast).to eq(
                mk_pair(mk_nat(1), mk_var('x'))
            )
        end
        it 'value を引数に取るペア生成の引数の数が異なる' do
            expect do @parser.parse("pair(1)") end.to raise_error(ArgumentError)
        end
        it '引数の型が value じゃない' do
            expect do @parser.parse("pair(1, ...)") end.to raise_error(ArgumentError)
        end
        it '式を引数に取るペア生成' do
            expect(@parser.parse("pair(+(y, 3), pair(1, 2))").ast).to eq(
                mk_pair(mk_bin_exp('+', mk_var('y'), mk_nat(3)), mk_pair(mk_nat(1), mk_nat(2)))
            )
        end
    end
    describe '条件分岐のパース' do 
        it '条件分岐を正しくパースできる' do
            expect(@parser.parse("if(1,2,3)").ast).to eq(
                mk_if(mk_nat(1), mk_nat(2), mk_nat(3))
            )
        end
        it '条件分岐の引数の数が足りない' do
            expect do @parser.parse("if(1,2)") end.to raise_error(ArgumentError)
        end
        it '条件分岐の引数の数が多い' do
            expect do @parser.parse("if(1,2,3,4)") end.to raise_error(ArgumentError)
        end
    end
    describe '再帰定義のパース' do 
        it '再帰定義がパースできる' do 
            expect(@parser.parse("letrec x = 3 in +(x, 7)").ast).to eq(
                mk_letrec('x', mk_nat(3), mk_bin_exp('+', mk_var('x'), mk_nat(7)))
            )
        end
        it '変数名の部分が変数名じゃない' do
            expect do @parser.parse("letrec 1 = 0 in if(1, 2, 3)") end.to raise_error(ArgumentError)
        end
    end
    describe 'send, recv, new のパース' do
        it 'send' do
            expect(@parser.parse("send(pair(1,2), true)").ast).to eq(
                mk_send(mk_pair(mk_nat(1), mk_nat(2)), mk_atom('true'))
            )
        end
        it 'recv' do
            expect(@parser.parse('recv(true)').ast).to eq(
                mk_recv(mk_atom('true'))
            )
        end
        it 'new' do
            expect(@parser.parse('new(\x.x)').ast).to eq(
                mk_new(mk_lambda('x', mk_var('x')))
            )
        end

        it 'send の引数が足りない' do
            expect do @parser.parse("send(123)") end.to raise_error(ArgumentError)
        end
        it 'recv の引数が足りない' do
            expect do @parser.parse('recv()') end.to raise_error(ArgumentError)
        end
        it 'new の引数が足りない' do
            expect do @parser.parse('new()') end.to raise_error(ArgumentError)
        end
        it 'send の引数が多い' do
            expect do @parser.parse("send(a, b, c)") end.to raise_error(ArgumentError)
        end
        it 'recv の引数が多い' do
            expect do @parser.parse('recv(a, b)') end.to raise_error(ArgumentError)
        end
        it 'new の引数が多い' do
            expect do @parser.parse('new(a, b)') end.to raise_error(ArgumentError)
        end
    end
    describe 'let 糖衣構文のパース' do
        it 'let がパースできる' do 
            expect(@parser.parse("let x = 3 in 5").ast).to eq(
                mk_let('x', mk_nat(3), mk_nat(5))
            )
        end
        it '変数名が変数名じゃない' do 
            expect do @parser.parse("let true = 3 in 5") end.to raise_error(ArgumentError)
        end
    end
    describe 'seq 糖衣構文のパース' do
        it 'seq の引数が 2つのケースをパースできる' do
            expect(@parser.parse('seq(1,2)').ast).to eq(
                mk_seq(mk_nat(1), mk_nat(2))
            )
        end
        it 'seq の引数が1つはダメ' do 
            expect do @parser.parse('seq(1)') end.to raise_error(ArgumentError)
        end
        it 'seq の引数が3つのケースをパースできる' do
            expect(@parser.parse('seq(1, 2, a)').ast).to eq(
                mk_seq2(mk_nat(1), mk_nat(2), mk_var('a'))
            )
        end
    end
    describe 'zコンビネータのパース' do
        it 'rec' do
            expect(@parser.parse('rec(f)').ast).to eq(
                mk_rec(mk_var('f'))
            )
        end
    end
    describe '関数適用のパース' do
        it '関数を適用する' do
            expect(@parser.parse("hoge_func(xxx)").ast).to eq(
                mk_app(mk_var('hoge_func'), mk_var('xxx'))
            )
        end
        it '関数適用の引数が2つはダメ' do
            expect do @parser.parse("hoge_func(1,2)") end.to raise_error(ArgumentError)
        end
    end
    describe '#valid_var?' do
        [
            ['abc', true],
            ['1', false],
            ['_', false],
        ].each do |input, expected|
            it '#valid_var?' do
                expect(@parser.valid_var?(input)).to eq(expected)
            end
        end
    end
end