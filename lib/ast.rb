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

    def substitute(var, exp)
        case @data
        in {type: 'nat', value:}
            return self
        in {type: 'atom', value:}
            return self
        in {type: 'var', value:value} if value == var
            return exp
        in {type: 'var', value:value}
            return self
        in {type: 'pair', first:first, second:second}
            return mk_pair(first.substitute(var, exp), second.substitute(var, exp))
        in {type: 'pair_builtin_app', name:name, value:value}
            return mk_pair_builtin(name, value.substitute(var, exp)) 
        in {type: 'bin_exp_app', ope:ope, left:left, right:right}
            return mk_bin_exp(ope, left.substitute(var, exp), right.substitute(var, exp))
        in {type: 'if', cond:cond, if_true:if_true, if_false:if_false}
            return mk_if(cond.substitute(var, exp),
             if_true.substitute(var, exp), if_false.substitute(var, exp))
        in {type: 'letrec', var:var_, value:value, target:target}
            return self if var_ == var
            return mk_letrec(var_, value.substitute(var, exp), target.substitute(var, exp))
        in {type: 'lambda', arg:arg, exp:func}
            return self if arg == var # 束縛変数は置換しない
            return mk_lambda(arg, func.substitute(var, exp))
        in {type: 'app', func:func, value:value}
            return mk_app(func.substitute(var, exp), value.substitute(var, exp))
        in {type:'send', data:data, dst:dst}
            return mk_send(data.substitute(var, exp), dst.substitute(var, exp))
        in {type: 'recv', action:action}
            return mk_recv(action.substitute(var, exp))
        in {type: 'new', action:action}
            return mk_new(action.substitute(var, exp))
        end
    end
    def to_hole_notation
        #{R: Astの次に評価される箇所をホールにしたもの Er: ホールと入れ替わったやつ }
        #ast = mk_app(mk_lambda('x', M), mk_new(N))
        #ast.redex? == false
        #(mk_new(N)).redex? == true
        #{R: mk_app(mk_lambda('x', M), mk_hole), Er: mk_new(N) }
        
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

    def to_s
        case @data
        # とりあえず repl から使う値型だけ
        in {type:'atom', value:value}
            value
        in {type:'nat', value:value}
            value.to_s
        in {type:'var', value:value}
            value
        in {type:'lambda', arg:arg, exp:exp}
            "λ#{arg}.#{exp}"
        in {type:'pair', first:first, second:second}
            "pair(#{first}, #{second})"
        in {type: 'if', cond:cond, if_true:if_true, if_false:if_false}
            "if(#{cond}, #{if_true}, #{if_false})"
        in {type:'bin_exp_app', ope:ope, left:left, right:right}
            "#{ope}(#{left}, #{right})"
        in {type:'pair_builtin_app', name:name, value:value}
            "#{name}(#{value.to_s})"
        in {type:'app', func:func, value:value}
            "(#{func})(#{value})"
        in {type:'letrec', var:var, value:value, target:target}
            "letrec #{var} = #{value} in (#{target})"
        in {type:'send', data:data, dst:dst}
            "send(#{data}, #{dst})"
        in {type:'recv', action:action}
            "recv(#{action})"
        in {type:'new', action:action}
            "new(#{action})"
        end
    end
end
class HoleNotation
    def to_s
        "ロ"
    end
    def ==
    end
    def []=
    end
    def []
    end
    def deconstruct_keys
    end
end
def mk_hole
    HoleNotation.new
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
