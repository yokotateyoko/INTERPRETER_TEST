class Ast
    attr_reader :data

    def initialize(data)
        @data = data
    end

    def val?
        case @data
        in {type:'atom' | 'nat' | 'var' | 'lambda', **rest}
            true
        in {type:'pair', first:, second:}
            first.val? && second.val?
        else
            false
        end
    end

    def reducible?
        case @data
        in {type:'bin_exp_app', ope:, left:left, right:right}
            left.val? && right.val?
        end
    end

    def ==(other)
        other.is_a?(Ast) && other.data == @data
    end

    def []=(key, value)
        @data[key] = value
    end
    def [](key)
        @data[key]
    end

    def deconstruct_keys(key)
        @data
    end
end

def mk_atom(value)
    Ast.new({type:'atom', value:})
end
def mk_nat(value)
    Ast.new({type:'nat', value:})
end
def mk_var(value)
    Ast.new({type:'var', value:})
end
def mk_pair(first, second)
    Ast.new({type:'pair', first:, second:})
end
def mk_bin_exp(ope, left, right)
    Ast.new({type:'bin_exp_app', left:, right:, ope:})
end
def mk_pair_builtin(name, value)
    Ast.new({type:'pair_builtin_app', value:, name:})
end
def mk_lambda(arg, exp)
    Ast.new({type:'lambda', arg:, exp:})
end
# cond, consequence, alternative
def mk_if(cond, if_true, if_false)
    Ast.new({type:'if', cond:, if_true:, if_false:})
end
def mk_letrec(var, value, target)
    Ast.new({type:'letrec', var:, value:, target:})
end
def mk_send(data, dst)
    Ast.new({type:'send', data:, dst:})
end
def mk_recv(action)
    Ast.new({type:'recv', action:})
end
def mk_new(action)
    Ast.new({type:'new', action:})
end
def mk_app(func, value)
    Ast.new({type:'app', func:, value:})
end
def mk_let(var, value, target)
    mk_app(mk_lambda(var, target), value)
end
def mk_seq(value, target)
    mk_let(mk_var('_'), value, target)
end
def mk_seq2(*args)
    return mk_seq(*args) if args.length == 2

    v0 = args.pop
    mk_seq(v0, mk_seq2(*args))
end
def mk_rec(func)
    xx = mk_app(mk_var('x'), mk_var('x'))
    xxy = mk_app(xx, mk_var('y'))
    yxxy = mk_lambda('y', xxy)
    fyxxy = mk_app(func, yxxy)
    xfyxxy = mk_lambda('x', fyxxy)

    mk_app(xfyxxy, xfyxxy)
end
