require 'configuration'

RSpec.describe ActorConfiguration do
    describe "#transition" do
        # actors, env, expected_actors, expected_data
        [
            # シンプルなsend(x, b)のパターン
            {actors:{'a' => mk_send(mk_var('x'), mk_var('b'))},
             env: [],
             expected_actors: {'a' => mk_atom('null')},
             expected_env: [['b', mk_var('x')]]},
            # sendが計算式の中にあるパターン
            {actors:{'a' => mk_bin_exp('+', mk_nat(1), mk_send(mk_var('x'), mk_var('b')))},
             env: [],
             expected_actors: {'a' => mk_bin_exp('+', mk_nat(1), mk_atom('null'))},
             expected_env: [['b', mk_var('x')]]},
            # シンプルなrecvのパターン
            {actors:{'a' => mk_recv(mk_lambda('x', mk_var('x')))},
             env: [['a', mk_nat(1)]],
             expected_actors: {'a' => mk_app(mk_lambda('x', mk_var('x')), mk_nat(1))},
             expected_env: []},
            # シンプルなnewのパターン
            {actors:{'a' => mk_new(mk_lambda('x', mk_var('x')))},
             env: [],
             expected_actors: {'a' => mk_var("a_1"), "a_1" =>mk_recv(mk_lambda('x', mk_var('x')))},
             expected_env: []},
            # ラムダ計算の簡約をするパターン
            {actors:{'a' => mk_bin_exp('+', mk_nat(1), mk_nat(1))},
             env: [],
             expected_actors: {'a' => mk_nat(2)},
             expected_env: []},
            # 複数遷移できるアクターがあるパターン
            {actors:{'a' => mk_bin_exp('+', mk_nat(1), mk_nat(1)), 'b' => mk_bin_exp('-', mk_nat(1), mk_nat(1))},
             env: [],
             expected_actors: {'a' => mk_nat(2), 'b' => mk_bin_exp('-', mk_nat(1), mk_nat(1))},
             expected_env: []},
        ].each do |params|
            params => {actors:actors, env:env, expected_actors:expected_actors, expected_env:expected_env}
            ac = ActorConfiguration.new(actors, env)
            it "遷移前: #{ac}" do
                ac.transition
                expect(ac.actors).to eq(expected_actors)
                expect(ac.env).to eq(expected_env)
            end
        end
    end
    describe "#transitionable?" do
        [
            # 式が評価できるときのパターン
            {actors:{'a' => mk_bin_exp('+', mk_nat(1), mk_nat(1))},
             env: [],
             expected: true
             },
            # 式が評価できないときのパターン
            {actors:{'a' => mk_bin_exp('+', mk_nat(1), mk_atom('true'))},
             env: [],
             expected: false
             },
            # 複数アクターがあるときのパターン
            {actors:{'a' => mk_bin_exp('+', mk_nat(1), mk_atom('true')), 'b' => mk_bin_exp('+', mk_nat(1), mk_nat(1))},
             env: [],
             expected: true
             },
            # recvのデータがあるパターン
            {actors:{'a' => mk_recv(mk_lambda('x', mk_var('x')))},
             env: [['a', mk_nat(1)]],
             expected: true
             },
            # recvのデータがないパターン
            {actors:{'a' => mk_recv(mk_lambda('x', mk_var('x')))},
             env: [['b', mk_nat(1)]],
             expected: false
             },
        ].each do |params|
            params => {actors:actors, env:env, expected:expected}
            ac = ActorConfiguration.new(actors, env)
            it "#{ac} -> #{expected}" do
                ac.transitionable?
                expect(ac.transitionable?).to eq(expected)
            end
        end
    end
    describe "#new_actor_name" do
        [
            [['a'], 'a', 'a_1'],
            [['a', 'a_1'], 'a', 'a_2'],
            [['a', 'a_1'], 'a_1', 'a_1_1'],
            [['a', 'a_1', 'b'], 'b', 'b_1'],
        ].each do |now_actors, parent_actor_name, new_actor_name|
            it "#{now_actors}, #{parent_actor_name} -> #{new_actor_name}" do
                actors = now_actors.map {|a| [a, mk_atom('null')]}.to_h
                ac = ActorConfiguration.new(actors, [])
                expect(ac.new_actor_name(parent_actor_name)).to eq(new_actor_name)
            end
        end
        # 現在存在しているアクター名のリスト
        # newするアクターの名前
        # 新規のアクター名
    end
end
