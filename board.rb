# Boardをクラスにしてしまった方が、deepcopyとかやりやすい？

class Board

    LENGTH = 28
    attr_reader :points

    def initialize(points = nil)
        # [0][25] are Goals, [26][27] are bars.
        @points = Array.new(LENGTH, 0)
        reset(points)
    end

    def reset(points = nil)
        if points
            if (points.size == LENGTH && points.all?{|x| x.is_a?(Integer)})
            # deepcopyの処理をする。
                (0...LENGTH).each do |i|
                    @points[i] = points[i]
                end
            else
                raise ArgumentError, "points must have 28 intergers."
            end
        else
            @points = [0, -2,0,0,0,0,5, 0,3,0,0,0,-5, 5,0,0,0,-3,0, -5,0,0,0,0,2, 0,0,0]
        end
    end

    def deepcopy
        new_board = Board.new(@points)
    end

    
    
    # ★これをオーバーライドすると違うゲームにできる？
    def check_terminal()
        if @points[25] == -15
            if @points[0] > 0
                [-1, true]
            else # should be @points[0] == 0
                [-2, true]
            end
        elsif @points[0] == 15
            if @points[25] < 0
                [1, true]
            else # should be @points[25] == 0
                [2, true]
            end
        else
            [0, false]
        end
    end

    def step(player, move)
        reward, done = check_terminal()
        player = player

        if done
            return [reward, done]
        end

        first_pos = move[0]
        next_pos = move[1]

        if player == 1
            @points[first_pos] -= 1
            if (@points[next_pos] == -1)
                # hit
                @points[27] += 1
                @points[next_pos] = 1
            else
                @points[next_pos] += 1
            end
        else # should be player == -1
            # player-1のチェッカーは、[1]-[25]ではマイナスだけど、[27]だけはプラスになる。
            if first_pos == 27
                @points[27] -= 1
            else
                @points[first_pos] += 1
            end

            if (@points[next_pos] == 1)
                # hit
                @points[26] += 1
                @points[next_pos] = -1
            else
                @points[next_pos] -= 1
            end
        end

        [0, false]
    end

    def all_possible_moves(player, rolls)
        moves = []

        if rolls.size == 2
            # ※ To be fixed.

            # possible_first_moves
            possible_move(player, rolls[1]).each do |m1|
                temp_board = self.deepcopy 
                done = temp_board.step(player, m1).at(1)
                # possible_second_moves
                temp_board.possible_move(player, rolls[0]).each do |m2|
                    moves.push([m1, m2])
                end
            end
=begin
            possible_move(player, rolls[0]).each do |m1|
                temp_board = self.deepcopy 
                done = temp_board.step(player, m1).at(1)
                # possible_second_moves
                temp_board.possible_move(player, rolls[1]).each do |m2|
                    moves.push([m2, m1])
                end
            end
=end
            # ※正規化はしていないのか？
        else # should be rolls.size == 4
            possible_move(player, rolls[1]).each do |m1|
                temp_board_1 = self.deepcopy
                done = temp_board_1.step(player, m1).at(1)
                # possible_second_moves
                temp_board_1.possible_move(player, rolls[1]).each do |m2|
                    temp_board_2 = temp_board_1.deepcopy
                    done = temp_board_2.step(player, m2).at(1)
                    # possible_third_moves
                    temp_board_2.possible_move(player, rolls[1]).each do |m3|
                        temp_board_3 = temp_board_2.deepcopy
                        done = temp_board_3.step(player, m3).at(1)
                        # possible_third_moves
                        temp_board_3.possible_move(player, rolls[1]).each do |m4|
                            moves.push([m1, m2, m3, m4])
                        end
                    end
                end
            end
        end

        if moves.empty?
            possible_move(player, rolls[0]).each do |m1|
                moves.push([m1])
            end
            possible_move(player, rolls[1]).each do |m1|
                moves.push([m1])
            end
        end

        moves
    end

    def possible_move(player, die)
        possible_moves = []
        terminal_moves = [] 
        bar_moves = [] # enter

        case player 
        when 1
            if @points[26] > 0
                pos = 25 - die
                if @points[pos] > -2
                    possible_moves.push([26, pos])
                    bar_moves.push([26, pos])
                end
            else
                if @points[7..24].all?{ |x| x <= 0} && @points[die] > 0
                    possible_moves.push([die, 0])
                    terminal_moves.push([die, 0])
                end
                
                possible_start_pos = (1..24).select{ |i| @points[i] > 0}
                
                # 次の2行は何をしているのか？(ll.332-333)

                possible_start_pos.each do |start_pos|
                    next_pos = start_pos - die
                    if next_pos > 0 && @points[next_pos] > -2
                        possible_moves.push([start_pos, next_pos])
                        terminal_moves.push([start_pos, next_pos])
                    end
                end
            end

            if bar_moves.empty? && @points[7..24].all?{ |x| x <= 0} && @points[26] == 0
                possible_start_pos = (1..24).select{ |i| @points[i] > 0}
                
                # 次の2行は何をしているのか？(ll.332-333)

                possible_start_pos.each do |start_pos|
                    if start_pos == die
                        possible_moves.push([start_pos, 0])
                    elsif  die > start_pos && terminal_moves.empty?
                        possible_moves.push([start_pos, 0])
                    end
                end
            end
        when -1
            if @points[27] > 0
                pos = die
                if @points[pos] < 2
                    possible_moves.push([27, pos])
                    bar_moves.push([27, pos])
                end
            else
                if @points[1..18].all?{ |x| x <= 0} && @points[25 - die] > 0
                    possible_moves.push([25-die, 25])
                    terminal_moves.push([25-die, 25])
                end
                
                possible_start_pos = (1..24).select{ |i| @points[i] < 0}
                
                possible_start_pos.each do |start_pos|
                    next_pos = start_pos + die
                    if next_pos < 25 && @points[next_pos] < 2
                        possible_moves.push([start_pos, next_pos])
                        terminal_moves.push([start_pos, next_pos])
                    end
                end
            end

            if bar_moves.empty? && @points[1..18].all?{ |x| x >= 0} && @points[27] == 0
                possible_start_pos = (1..24).select{ |i| @points[i] < 0}
                
                possible_start_pos.each do |start_pos|
                    if (25 - start_pos) == die
                        possible_moves.push([start_pos, 25])
                    elsif  die > (25 - start_pos) && terminal_moves.empty?
                        possible_moves.push([start_pos, 25])
                    end
                end
            end
        end

        possible_moves

    end

end



# Tests

#=begin 
board = Board.new
p board.all_possible_moves(1, [5,5,5,5])

board = Board.new([2, -2,3,3,3,2,2, 0,0,0,0,0,-5, 0,0,0,0,-3,0, -5,0,0,0,0,0, 0,0,0])
p board.all_possible_moves(1, [6,5])

board = Board.new([0, -2,3,3,3,2,2, 0,0,0,0,0,-5, 0,0,0,0,-3,0, -5,0,0,0,0,0, 0,2,0])
p board.all_possible_moves(1, [4,5])
p board.all_possible_moves(1, [2,6])

board = Board.new([12, -2,0,0,2,1,0, 0,0,0,0,0,-5, 0,0,0,0,-3,0, -5,0,0,0,0,0, 0,0,0])
p board.all_possible_moves(1, [1,6])

board = Board.new([0, 4,-1,0,0,-1,3, 0,3,0,0,-1,0, 1,0,0,0,-2,-1, -6,-2,1,-1,3,0, 0,0,0])
p board.all_possible_moves(1, [5,5,5,5])

board = Board.new([0, -2,0,0,0,0,5, 0,5,0,0,0,-3, 3,-2,0,0,-2,0, -5,0,-1,0,1,0, 0,1,0])
p board.all_possible_moves(1, [6,4])
p board.all_possible_moves(1, [4,6])

board = Board.new([0, -2,4,-3,-2,4,3, 0,3,0,0,0,0, 0,-1,0,1,0,0, -4,0,0,-1,0,-1, 0,0,1])
p board.all_possible_moves(-1, [5,1])
p board.all_possible_moves(-1, [1,5])

#=end
