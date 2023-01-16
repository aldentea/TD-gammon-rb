

class BackGammon

    attr_reader :board

    def initialize
        #reset 
        #@moves_4 = []
        @player = 0
        @random = Random.new
        @board = Board.new
    end

    def reset
        @board.reset
    end

    def roll
        d1 = @random.rand(6) + 1
        d2 = @random.rand(6) + 1
        d1 == d2 ? Array.new(4, d1) : [d1, d2]
    end

    def random_player
        @random.rand < 0.5 ? 1 : -1
    end

    def change_player
        @player *= -1
    end


end

