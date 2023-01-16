require 'torch'


class Network < Torch::NN::Module
    def initialize(lamda = 0.7, lr = 0.04)
        super()
        @hidden1 = Torch::NN::Sequential.new(
            Torch::NN::Linear.new(198, 80),
            Torch::NN::Sigmoid.new()
        )
        @output = Torch::NN::Sequential.new(
            Torch::NN::Linear(80, 1),
            Torch::NN::Sigmoid()
        )
        # ※メンバ変数でいいのか？
        @env = Backgammon.new
        @lamda = lamda
        @lr = lr
    end

    def forward(x)
        x = @hidden1.call(x)
        @output.call(x)
    end

    def train(iters)
        agent = TDAgent.new(self)
        gen_count_new = 0
        gen_count_old = 0

        (0...iters).each do |i|
            @env.reset
            init_eligibility_trace

            rolls = @env.roll_dice()
            player = env.random_player()

            @env.player = player
            
            puts("Calculating Weights: {i}")
            step = 0
            
            # Saving Model every 100 steps
            if count % 100 == 0
                Torch.save(state_dict, "net.pth")

            fake_1 = env # ※deepcopyする。
            #winner_random = play_random_test

            loop do
                puts ("\t\t\t\t Working on Step {step}.")
                features = Torch.tensor(@env.board_features)
                p = forward(features)
                fake_board = @env.board # ※deep copyする
                actions = @env.all_possible_moves(player, fake_board, rolls)

                if !actions.empty?
                    fake = @env # ※deepcopyする
                    action, win_prob = agent.select_best_action(actions, fake, player)
                    if !action.empty?
                        action.each do |a|
                            reward, done = env.step(a, env.board, player)
                        end
                    end
                end
                features = Torch.tensor(env.board_features)
                p_next = forward(features)

                if done
                    loss = update_weights(p, reward)
                    break
                else
                    loss = update_weights(p, p_next)
                end

                player = @env.change_player(player)
                rolls = env.roll_dice()
            end
        end
    end


    def play_with_weights(p)
        init_eligibility_trace()
        zero_grad()
        p.backward
    end

    def init_eligibility_trace
        @eligibility_traces = [Torch.zeros(weights.shape), require_grad: false]
    end

    def update_weights(p, p_next)
        zero_grad
        p.backward

        Torch.no_grad do
            td_error = p_next - p
            
            parameters.each_with_index do |weights, i|
                @lamda = 0.7
                @lr = 0.04
                eligibility_traces[i] = lamda * eligibility_traces[i] * weights.grad
                new_weights = weights + lr * td_error * eligibility_traces[i]
                weights.copy!(new_weights)
                # weightsをnew_weightsで更新するということ？どうやってやるの？
            end
        end

        td_error
    end
end

# Training

model = Network.new

i = ARGV.size > 0 ? ARGV[0].to_i : 0
i = i > 0 ? i : 100
puts("#{i} times Iterations.")
model.train(i)

