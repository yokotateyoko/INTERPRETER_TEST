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
        return nil unless self.reducible?
        case @data
        in {type:'bin_exp_app', left:left, right:right, ope:ope}
            if left.reducible?
                left_ = left.to_hole_notation
                return HoleNotation.new(mk_bin_exp(ope, left_.reduce_context, right), left_.reducible_expression)
            elsif right.reducible?
                right_ = right.to_hole_notation
                return HoleNotation.new(mk_bin_exp(ope, left, right_.reduce_context), right_.reducible_expression)
            else
                return HoleNotation.new(mk_hole, self)
            end
        in {type:'pair_builtin_app', name:name, value:value}
            if value.reducible?
                value_ = value.to_hole_notation
                return HoleNotation.new(mk_pair_builtin(name, value_.reduce_context), value_.reducible_expression)
            else
                return HoleNotation.new(mk_hole, self)
            end
        in {type: 'if', cond:cond, if_true:if_true, if_false:if_false}
            if cond.reducible?
                cond_ = cond.to_hole_notation
                return HoleNotation.new(mk_if(cond_.reduce_context, if_true, if_false), cond_.reducible_expression)
            else
                return HoleNotation.new(mk_hole, self)
            end
        in {type:'pair', first:first, second:second}
            if first.reducible?
                first_ = first.to_hole_notation
                return HoleNotation.new(mk_pair(first_.reduce_context, second), first_.reducible_expression)
            elsif second.reducible?
                second_ = second.to_hole_notation
                return HoleNotation.new(mk_pair(first, second_.reduce_context), second_.reducible_expression)
            else
                return nil
            end
        in {type:'letrec', var:var, value:value, target:target}
            if value.reducible?
                value_ = value.to_hole_notation
                return HoleNotation.new(mk_letrec(var, value_.reduce_context, target), value_.reducible_expression)
            else
                return HoleNotation.new(mk_hole, self)
            end
        in {type:'app', func:func, value:value}
            if func.reducible?
                func_ = func.to_hole_notation
                return HoleNotation.new(mk_app(func_.reduce_context, value), func_.reducible_expression)
            elsif value.reducible?
                value_ = value.to_hole_notation
                return HoleNotation.new(mk_app(func, value_.reduce_context), value_.reducible_expression)
            else
                return HoleNotation.new(mk_hole, self)
            end
        in {type:'send', data:data, dst:dst}
            if data.reducible?
                data_ = data.to_hole_notation
                return HoleNotation.new(mk_send(data_.reduce_context, dst), 
                                        data_.reducible_expression)
            elsif dst.reducible?
                dst_ = dst.to_hole_notation
                return HoleNotation.new(mk_send(data, dst_.reduce_context), 
                                        dst_.reducible_expression)
            else
                return HoleNotation.new(mk_hole, self)
            end
        in {type:'recv', action:action}
            if action.reducible?
                action_ = action.to_hole_notation
                return HoleNotation.new(mk_recv(action_.reduce_context), action_.reducible_expression)
            else
                return HoleNotation.new(mk_hole, self)
            end 
        in {type:'new', action:action}
            if action.reducible?
                action_ = action.to_hole_notation
                return HoleNotation.new(mk_new(action_.reduce_context), action_.reducible_expression)
            else
                return HoleNotation.new(mk_hole, self)
            end 
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
        in {type:'hole'}
            "[ ]"
        end
    end

    def modify(&modifier)
        ast = self.clone
        modified_ast = modifier.call(ast)
        ast.data.each do |k, v|
            ast.data[k] = v.modify(&modifier) if v.is_a?(Ast)
        end
        modified_ast
    end
end
class HoleNotation
    # reduce_context : hole を含む AST
    # reducible_expression : AST
    def initialize(reduce_context, reducible_expression)
        @reduce_context = reduce_context
        @reducible_expression = reducible_expression
    end
    attr_reader :reduce_context, :reducible_expression

    def to_ast(replace)
        # ruby は hash の挿入順が維持されるので
        # each で挿入順の若い方から見ていく
        # hole は1つしかないので1回だけ置換されるはず
        @reduce_context.modify do |ast|
            case ast
            in {type:'hole'}
                replace
            else
                ast
            end
        end
    end
    def to_s
        "#{@reduce_context} > #{@reducible_expression} <"
    end
    def ==(other)
        other.is_a?(HoleNotation) && 
        self.reduce_context == other.reduce_context &&
        self.reducible_expression == other.reducible_expression
    end
    def []=
    end
    def []
    end
    def deconstruct_keys
    end
end
def mk_hole
    Ast.new({type: 'hole'})
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
