# +(+(1,1), 1) -> +(2, 1)
def reduce(ast)
    case ast
    in {type: 'bin_exp_app', ope:ope, left: left, right: right}
        return mk_bin_exp(ope, reduce(left), right) unless left.val?
        return mk_bin_exp(ope, left, reduce(right)) unless right.val?

        return mk_atom(left == right ? 'true' : 'false') if ope == '='

        [left, right] => [{type:'nat', value:left_val}, {type:'nat', value:right_val}]
        case ope
        in '+'
            return mk_nat(left_val + right_val)
        in '-' if left_val < right_val
            return mk_nat(0)
        in '-'
            return mk_nat(left_val - right_val)
        in '*'
            return mk_nat(left_val * right_val)
        in '/'
            return mk_nat(left_val / right_val)
        end
    end
end
