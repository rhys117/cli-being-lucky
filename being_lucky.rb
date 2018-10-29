module UserInterface
  def clear_screen
    system('clear') || system('cls')
  end

  def puts_styled(msg)
    puts "--> #{msg}"
  end

  def line_break
    puts ''
  end

  def horizontal_line
    puts "----------------------------------"
  end

  def sleep_message(msg)
    return unless msg.length.positive?

    sleep 0.5
    puts_styled msg
    sleep 1.5
  end
end

class Player
  attr_accessor :scoring, :total_score, :current_roll, :valid_dice, :round_score,
                :number

  def initialize(num)
    @number = num
    @scoring = false
    @total_score = 0
    @round_score = 0
    @current_roll = nil
    @valid_dice = 5
  end

  def rolls
    @current_roll = DiceRoll.new(random_roll)
    if @scoring
      @round_score += @current_roll.throw_score
    elsif @current_roll.throw_score >= BeingLuckyFullGame::MINIMUM_STARTING_SCORE
      @scoring = true
      @round_score += @current_roll.throw_score
    end
    @valid_dice -= @current_roll.used_dice
    @valid_dice = 5 if @current_roll.all_scoring
  end

  def reset_after_round
    @total_score += @round_score
    @round_score = 0
    @current_roll = nil
    @valid_dice = 5
  end

  private

  def random_roll
    random_roll_array = []
    @valid_dice.times { |_| random_roll_array << DiceRoll::ROLL_RANGE.sample(1)[0] }
    random_roll_array.join
  end
end

class DiceRoll
  ROLL_RANGE = (1..6).to_a

  SCORING_CONDITIONS = [['111', 1000],
                        ['666', 600],
                        ['555', 500],
                        ['444', 400],
                        ['333', 300],
                        ['222', 200],
                        ['1',   100],
                        ['5',   50],].freeze

  attr_reader :throw_score, :roll, :all_scoring

  def initialize(roll)
    @all_scoring = false
    @roll = sorted_roll(roll)
    @scoring_dice = 0
    @throw_score = populate_throw_score
  end

  def used_dice
    @all_scoring == 5 ? 0 : @scoring_dice
  end

  private

  def sorted_roll(roll)
    roll.split('').map(&:to_i).sort.join
  end

  def populate_throw_score
    score = 0
    roll_clone = @roll.clone

    SCORING_CONDITIONS.each do |cond_and_points|
      score_condition, points = cond_and_points
      next unless roll_clone.include?(score_condition)

      roll_clone.sub!(score_condition, '')
      score += points
      @scoring_dice += score_condition.length
      redo
    end
    @all_scoring = true if roll_clone.length.zero?
    score
  end
end

class BeingLucky
  def initialize(dice)
    @roll = dice
  end

  def score
    DiceRoll.new(@roll).throw_score
  end
end

class BeingLuckyFullGame
  include UserInterface

  MINIMUM_STARTING_SCORE = 300
  FINAL_ROUND_POINTS = 3000

  def initialize
    clear_screen
    welcome_message
    @number_of_players = query_number_of_players
    initialize_players
    @final_round = false
  end

  def play
    loop do
      @players.each do |player|
        if @first_finished == player.number
          @final_round = true
          break
        end

        @current_player = player
        take_turn

        @current_player.reset_after_round
        @first_finished = player.number if @current_player.total_score >= FINAL_ROUND_POINTS
      end

      break if @final_round
    end

    display_final_scores
  end

  private

  def display_final_scores
    clear_screen
    puts_styled "Game over. Final scores:"
    horizontal_line
    @players.each do |player|
      puts_styled "player #{player.number}: #{player.total_score}"
    end
  end

  def query_number_of_players
    horizontal_line
    puts_styled "How many people are playing?"
    number_of_players = ''
    loop do
      number_of_players = gets.chomp.downcase.to_i
      break if number_of_players > 1 && number_of_players < 10

      puts_styled "Sorry, must choose between 2 - 9."
    end
    number_of_players
  end

  def welcome_message
    horizontal_line
    puts_styled "Welcome to Being Lucky!"
    horizontal_line
  end

  def initialize_players
    @players = []
    @number_of_players.times { |num| @players << Player.new(num + 1) }
  end

  def take_turn
    loop do
      display_current_score

      if !@current_player.current_roll.nil? && @current_player.current_roll.throw_score.zero?
        @current_player.round_score = 0
        sleep_message "You rolled a 0. Turn over. Round points lost"
        break
      end

      puts_styled "(T)hrow dice or (H)old score"
      rolling = ''
      loop do
        rolling = gets.chomp.downcase.strip
        break if %w(t h).include?(rolling)

        puts_styled "Sorry, must choose T or H."
      end
      break if rolling == 'h' || @current_player.valid_dice <= 0

      @current_player.rolls
    end
  end

  def display_current_score
    clear_screen
    puts_styled "Player #{@current_player.number} Turn:"
    if @current_player.current_roll
      puts_styled "Player just rolled: #{@current_player.current_roll.roll}"
      puts_styled "Last roll points: #{@current_player.current_roll.throw_score}"
    end
    puts_styled "Available dice: #{@current_player.valid_dice}"
    puts_styled "Cumulative Score: #{@current_player.total_score}"
    puts_styled "Round Score: #{@current_player.round_score}"
    horizontal_line
  end
end

# puts BeingLucky.new('24454').score
BeingLuckyFullGame.new.play
