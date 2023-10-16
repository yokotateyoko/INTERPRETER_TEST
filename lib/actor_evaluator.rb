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
    in {type: 'pair_builtin_app', name: name, value: value}
        return mk_pair_builtin(name, reduce(value)) unless value.val?

        return mk_atom(value[:type] == 'pair' ? 'true' : 'false') if name == 'is_pair?'
        value => {type:'pair', first: first, second: second}
        case name
        in '1st'
            return first
        in '2nd'
            return second
        end
    in {type:'if', cond:cond, if_true:if_true, if_false:if_false}
        return mk_if(reduce(cond), if_true, if_false) unless cond.val?
        case cond
        in {type:'atom', value:'true'}
            return if_true
        in {type:'atom', value:'false'}
            return if_false
        end
    in {type:'pair', first:first, second:second}
        return mk_pair(reduce(first), second) unless first.val?
        return mk_pair(first, reduce(second)) unless second.val?
        raise ArgumentError.new('なんかおかしいぞ！')
    in {type:'app', func:func, value:value}
        return mk_app(reduce(func), value) unless func.val?
        return mk_app(func, reduce(value)) unless value.val?
        func => {type:'lambda', arg:arg, exp:exp}
        exp.substitute(arg, value)
    in {type:'letrec', var:var, value:value, target:target}
        return mk_letrec(var, reduce(value), target) unless value.val?
        target.substitute(var, value.substitute(var, mk_letrec(var, value, value)))
    in {type:'send', data:data, dst:dst}
        return mk_send(reduce(data), dst) unless data.val? 
        return mk_send(data, reduce(dst)) unless dst.val? 
        return mk_atom('null')
    in {type:'recv', action:action}
        return mk_recv(reduce(action)) unless action.val?
        #return mk_app(action, value)
    end
end

class Ast
    def reducible?
        begin
            # self が λ計算の操作的意味論で簡約できない場合は、 reduce(self) は例外を投げるようになっている
            reduce(self)
            true
        rescue
            false
        end
    end
end
