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
             expected_actors: {'a' => mk_var("a'"), "a'" =>mk_recv(mk_lambda('x', mk_var('x')))},
             expected_env: []},
            # ラムダ計算の簡約をするパターン
            {actors:{'a' => mk_bin_exp('+', mk_nat(1), mk_nat(1))},
             env: [],
             expected_actors: {'a' => mk_nat(2)},
             expected_env: []},
            # 複数遷移できるアクターがあるパターン
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
end
