require_relative 'ast'
require_relative 'actor_evaluator'

class ActorConfiguration
    attr_reader :actors, :env
    def initialize(actors={}, env=[])
        # actor 名と式の hash
        @actors = actors
        # actor 名と送信データ (AST) のタプルの配列
        @env = env
    end

    def get_sending_data(name)
        env.find {|st| st[0] == name}
    end
    # ac = [+(1,1)]a, [true]b || []
    # ac.transition
    # ac = [2]a, [true]b || []
    def transition
        # TODO 1度に1個の遷移だけ行うようにする
        new_actors = {}
        @actors.each do |name, _|
            exp = @actors[name]
            # 環境に送信状態を追加
            hole_notation = exp.to_hole_notation
            next if hole_notation.nil?
            case hole_notation.reducible_expression
            in {type:'send', data:data, dst:dst}
                next unless dst[:type] == 'var'
                @actors[name] = hole_notation.to_ast(mk_atom('null'))
                @env << [dst[:value], data]
            in {type:'recv', action:action}
                next if get_sending_data(name).nil?
                data = get_sending_data(name)
                @env.delete(data)
                @actors[name] = mk_app(action, data[1])
            in {type:'new', action:action}
                # TODO 名前被りがないかチェックする
                new_name = name + "'"
                new_actors[new_name] = mk_recv(action)
                @actors[name] = hole_notation.to_ast(mk_var(new_name))
            else
                @actors[name] = hole_notation.to_ast(reduce(hole_notation.reducible_expression))
            # in {type:'app'}
            end
        end
        @actors.merge!(new_actors)
    end
    def to_s
        str = actors.map{|name, exp| "[#{exp}]#{name}" }.join(', ')
        str += " || "
        str += "{" + env.map{|name, val| "#{name} <= #{val}"}.join(',') + "}"
    end
end
