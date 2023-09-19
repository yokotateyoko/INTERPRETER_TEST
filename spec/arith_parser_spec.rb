# require "lib/parser.rb"
require "arith_parser"

RSpec.describe 'Parser' do
    describe '数値のパース' do
        it '1 がパースできる' do
            expect(parse('1').get_num).to eq(1)
        end

        it 'aaa はパースできない' do
            expect(parse('aaa')).to be_nil
        end

        it '00001 はパースできない' do
            expect(parse('00001')).to be_nil
        end

        it '0 はパースできる' do
            expect(parse('0')).not_to be_nil
        end
    end

    describe 'n1 + n2 のパース' do
        it '1 + 2 がパースできる' do
            ast = parse('1 + 2').ast
            expect(ast[:left]).to eq(1)
            expect(ast[:right]).to eq(2)
        end
        it '1+2' do
            input = RSpec.current_example.description
            ast = parse(input).ast
            expect(ast[:left]).to eq(1)
            expect(ast[:right]).to eq(2)
        end
    end
end
