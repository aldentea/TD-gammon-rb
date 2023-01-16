require 'torch-rb'

class TDAgent

    include BoardTDInput

    def initialize(net)
        @net = net
    end

    def select_best_action(actions, board, player)
        best_action = []
        win_prob = 0

        if !actions.empty?
            n = actions.size
            values = Array.new(n, 0.0)
            (0...n).each do |i|
                fake_board = board.deepcopy
                action.each do |m|  # 1つのactionは、複数のmoveからなる配列である。
                    done = fake_board.step(player, m).at(1)
                end
                features = Torch.tensor(board_features(fake_board)) # 198d-input
                values[i] = @net.forward(features).first
            end

            case player
            when 1
                win_prob = values.max
                best_action_index = values.index(win_prob)
            when -1
                win_prob = values.min
                best_action_index = values.index(win_prob)
            end

            best_action = actions[best_action_index]
        end

        [best_action, win_prob]
    end
    

