require 'torch'

require_relative 'environment'
require_relative 'TD_agent'
require_relative 'board_td_input'


class Network < Torch::NN::Module

    include BoardTDInput

    FILENAME = "net.pth"

    def initialize(lambda = 0.7, lr = 0.04)
        super()
        @hidden1 = Torch::NN::Sequential.new(
            Torch::NN::Linear.new(198, 80),
            Torch::NN::Sigmoid.new()
        )
        @output = Torch::NN::Sequential.new(
            Torch::NN::Linear.new(80, 1),
            Torch::NN::Sigmoid.new()
        )
        # ※メンバ変数でいいのか？
        @env = Backgammon.new
        @lambda = lambda
        @lr = lr
    end

    def forward(x)
        x = @hidden1.call(x)
        @output.call(x)
    end

    def train(iters)
        agent = TDAgent.new(self)
        count = 0
        gen_count_new = 0
        gen_count_old = 0

        (0...iters).each do |i|
            @env.reset
            init_eligibility_trace

            rolls = @env.roll
            player = @env.random_player()

            @env.player = player
            
            puts("Calculating Weights: #{i}")
            step = 0
            
            count += 1
            # Saving Model every 100 steps
            if count % 100 == 0
                Torch.save(state_dict, FILENAME)
            end

            fake_1 = @env # ※deepcopyする。
            #winner_random = play_random_test

            loop do
                puts ("\t\t\t\t Working on Step #{step}.")
                step += 1
                reward = 0.0
                done = false

                p @env.board
                p rolls

                bf = board_features(@env.board, @env.player)
                features = Torch.tensor(bf)
                pp = forward(features)
                fake_board = @env.board # ※deep copyする
                actions = fake_board.all_possible_moves(player, rolls)

                if !actions.empty?
                    fake = @env # ※deepcopyする
                    action, win_prob = agent.select_best_action(actions, fake.board, player)
                    p action
                    if !action.empty?
                        action.each do |a|
                            reward, done = @env.board.step(player, a)
                        end
                    end
                end
                features = Torch.tensor(board_features(@env.board, @env.player))
                p_next = forward(features)

                if done
                    loss = update_weights(pp, reward)
                    break
                else
                    loss = update_weights(pp, p_next)
                end

                player = @env.change_player
                rolls = @env.roll
            end
        end
        Torch.save(state_dict, FILENAME)
    end


    def play_with_weights(pp)
        init_eligibility_trace()
        zero_grad()
        pp.backward
    end

    def init_eligibility_trace
        parameters
        @eligibility_traces = parameters.map { 
            |weights| Torch.zeros(*weights.shape, requires_grad: false)
        }
    end

    def update_weights(pp, p_next)
        zero_grad
        pp.backward
        td_error = 0.0
        Torch.no_grad do
            td_error = p_next - pp
            
            parameters.each_with_index do |weights, i|
                @eligibility_traces[i] = @lambda * @eligibility_traces[i] * weights.grad
                new_weights = weights + @lr * td_error * @eligibility_traces[i]
                weights.copy!(new_weights)
                # weightsをnew_weightsで更新するということ？どうやってやるの？
            end
        end

        td_error
    end
end

# Training

model = Network.new
if File.exist?(Network::FILENAME)
    model.load_state_dict(Torch.load(Network::FILENAME))
end

i = ARGV.size > 0 ? ARGV[0].to_i : 0
i = i > 0 ? i : 100
puts("#{i} times Iterations.")
model.train(i)

