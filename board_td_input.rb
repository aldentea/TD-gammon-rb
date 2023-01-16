
module BoardTDInput

    def board_features(board)
        players = [1, -1]
        features_vector = []

        # input 1 to 192
        players.each do |player|
            1.upto(24) do |i|
                point = board.points[i]
                if player * point > 0
                    features_vector += case point.abs
                    when 1
                        [1.0, 0.0, 0.0, 0.0]
                    when 2
                        [1.0, 1.0, 0.0, 0.0]
                    else
                        [1.0, 1.0, 1.0, (point.abs - 3.0)/2.0]
                    end
                else
                    features_vector += [0.0, 0.0, 0.0, 0.0]
                end
            end
        end

        # input 193 to 196
        players.each do |player|
            non_bar_units = board.points[1..24].select{ |x| x * player > 0 }.sum
            bar_units = board.points[player > 0 ? 26: 27]
            features_vector += [bar_units / 2.0, non_bar_units / 15.0]
        end

        # input 197 to 198
        features_vector += player > 0 ? [1.0, 0,0] : [0.0, 1.0]

        features_vector.flatten

    end

end
