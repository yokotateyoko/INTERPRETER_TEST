# +(+(1,1), 1) -> +(2, 1)
def reduce(ast)
    case ast
    in {type: 'bin_exp_app', ope:'+', left: left, right: right}
        return mk_bin_exp('+', reduce(left), right) unless left.val?
        return mk_bin_exp('+', left, reduce(right)) unless right.val?
        case [left, right]
        in [{type:'nat', value:left_val}, {type:'nat', value:right_val}]
            return mk_nat(right_val + left_val)
        end
    end
end
