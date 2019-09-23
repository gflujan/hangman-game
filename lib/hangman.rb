# --------------------------------------------- 
# DEFINING THE HANGMAN GAME CLASS 
# --------------------------------------------- 
class Hangman 
  attr_reader :guesser, :referee, :board; 

  STICK_FIGURE = { 
    head: 'H', 
    body: 'B', 
    leg_left: 'LL', 
    leg_right: 'LR', 
    arm_left: 'AL', 
    arm_right: 'AR', 
  }; 

  def initialize(players={}) 
    defaults = {
      guesser: 'bueller', 
      referee: 'sloane', 
    }; 

    players = defaults.merge(players); 

    @guesser = players[:guesser]; 
    @referee = players[:referee]; 
    @board = []; 
    @guess_status = nil; 
    @num_wrong_guesses = 0; 
  end 

  def play() 
    self.setup(); 
    self.take_turn() until won? || @num_wrong_guesses >= 6; 
    puts 
    self.conclude(); 
  end 

  def setup() 
    @secret_word_length = @referee.pick_secret_word(); 
    @guesser.register_secret_length(@secret_word_length); 

    @secret_word_length.times() do 
      @board << nil
    end 
  end 

  def take_turn() 
    puts 
    guessed_letter = @guesser.guess(@board); 
    puts 
    matching_spots = @referee.check_guess(guessed_letter); 

    if matching_spots.length() < 1 
      @guess_status = :bad; 
      @num_wrong_guesses += 1; 
    else 
      @guess_status = :good; 
      self.update_board(guessed_letter, matching_spots); 
    end 

    @guesser.handle_response(guessed_letter, matching_spots); 
    self.render_board(); 
    puts 
    puts 
    self.render_figure(@num_wrong_guesses, @guess_status); 
    puts 
  end 

  def update_board(lttr, spots) 
    spots.each() { |idx| @board[idx] = lttr }; 
  end 

  def render_board() 
    @board.each() { |ele| print ele == nil ? '_' : ele }; 
  end 

  # This method to render the figure mostly works. It increments correctly when the user has a wrong guess 
  # But any correct guess ignores all of this and the persistent state of which parts have been revealed are not seen 
  # The user only see's the figure when they have a wrong guess 
  def render_figure(num, status) 
    # put an incoming status, and use an if statement to determine what the guesser's last status was 
    pieces = []; 

    if status == :bad 
      case num 
      when 1 
        puts "   [head]"; 
      when 2 
        puts "   [head]"; 
        puts "   [body]"; 
      when 3 
        puts "   [head]"; 
        puts "   [body]"; 
        puts "   [left arm]"; 
      when 4 
        puts "   [head]"; 
        puts "   [body]"; 
        puts "   [left arm]"; 
        puts "   [right arm]"; 
      when 5 
        puts "   [head]"; 
        puts "   [body]"; 
        puts "   [left arm]"; 
        puts "   [right arm]"; 
        puts "   [left leg]"; 
      when 6 
        puts "   [head]"; 
        puts "   [body]"; 
        puts "   [left  arm]"; 
        puts "   [right arm]"; 
        puts "   [left  leg]"; 
        puts "   [right leg]"; 
      else 
        puts " [    ] "; 
      end 
    end 
  end 

  def won?() 
    !@board.include?(nil); 
  end 

  def conclude() 
    puts 'The game has ended.'; 
    puts '{Insert name of player/comp who won the game}'; 
    puts 'Now go home you dirty hipster!'; 
    puts 
  end 
end 


# --------------------------------------------- 
# DEFINING THE HUMAN PLAYER CLASS 
# --------------------------------------------- 
class HumanPlayer 
  attr_reader :name; 

  def initialize(name) 
    @name = name; 
    @guesses = []; 
  end 

  def pick_secret_word() 
    puts 
    puts "#{@name}, enter the length of the secret word that you would like the other player to guess: "; 
    length = gets.chomp().to_i(); 
    return length; 
  end 

  def register_secret_length(length) 
    # 
  end 

  def guess(board) 
    puts "Hi #{@name}, what letter would you like to guess?"; 
    letter = gets.chomp(); 
    
    while @guesses.include?(letter) 
      puts 
      puts "You've already tried guessing that. Please enter a different letter."; 
      letter = gets.chomp(); 
    end 

    @guesses << letter; 
    return letter; 
  end 

  def check_guess(letter) 
    puts "The other player has guessed the letter \"#{letter.upcase()}\"."; 
    puts "Please enter the numbered positions (left to right) where the other player guessed correctly: "; 
    puts "  (e.g. 0,1 or 2,3)"; 
    puts "If no positions match, leave this blank and press enter."; 
    user_spots = gets.chomp(); 
    spots = user_spots.delete(' ').split(',').map(&:to_i); 
    return spots;  
  end 

  # My old version of what I thought this should do 
  def handle_response(letter, spots) 
    puts spots.length() > 0 ? 
      "Eureka! The letter you guessed matches!" : 
      "D'oh! Your guess wasn't correct this time but try again."; 
  end 

  # New version ... 
  # def handle_response(letter, spots) 
  #   # 
  # end 
end 

# --------------------------------------------- 
# DEFINING THE COMPUTER PLAYER CLASS 
# --------------------------------------------- 
class ComputerPlayer 
  attr_reader :dictionary; 

  def initialize(dict=self.default_dict()) 
    # Use .delete_if() {} to get rid of words that don't have the guessed letter 
    @dictionary = dict; 
    @guesses = []; 
  end 

  def default_dict() 
    dd = []; 

    File.open("./dictionary.txt", "r") do |f| 
      f.readlines() do |line| 
        dd << line.chomp(); 
      end 
    end 

    return dd; 
  end 

  def candidate_words() 
    return @dictionary; 
  end 

  # I want to do something like this that duplicates the incoming dictionary 
  # So that we can reference it for whatever reason, if needed 
  # def candidate_words() 
  #   @candidates = @dictionary.dup(); 
  #   p "These are my candidates: #{@candidates}"; 
  #   return @candidates; 
  # end 

  def pick_secret_word() 
    @secret_word = @dictionary.sample(); 
    return @secret_word.length(); 
  end 

  def register_secret_length(length) 
    @dictionary.reject!() { |word| word.length() != length }; 
  end 

  # This is the version of the method for randomly guessing letters 
  # I have to test the pitfall catch for when a letter has already been guessed 
  # def guess(board) 
  #   alphabet = ('a'..'z').to_a(); 
    
  #   while @guesses.include?(letter) 
  #     board.each() do |ele| 
  #       letter = alphabet.sample() if ele == nil; 
  #     end 
  #   end 

  #   @guesses << letter; 
  #   return letter; 
  # end 

  # This is the version for the comp to intelligently guess letters 
  def guess(board) 
    letter_counts = Hash.new(0); 
    nil_spots = []; 

    if board.all?() { |ele| ele == nil }; 
      @dictionary.each() do |word| 
        word.each_char() { |ch| letter_counts[ch] += 1 }; 
      end 
    else 
      @dictionary.each() do |word| 
        word.each_char().with_index() do |ch, idx| 
          letter_counts[ch] += 1 if board[idx] == nil; 
        end 
      end 
    end 

    sorted = letter_counts.sort_by() { |k,v| v }; 
    # letter = sorted.last().first(); 

    # I don't think I need this pitfall catch here in the "intelligent guess" version 
    # It seems that it would be more beneficial in the "random guess" version above 
    # while @guesses.include?(letter) 
    #   self.guess(board);  # I think this will get caught in an endless loop like the HumanPlayer
    #                       # I want to return this back to the Hangman.take_turn instance method 
    # end 

    # @guesses << letter; 
    # return letter; 
    return sorted.last().first(); 
  end 

  def check_guess(lttr) 
    spots = []; 

    @secret_word.each_char().with_index() do |ch, idx| 
      spots << idx if ch == lttr; 
    end 

    return spots;  
  end 

  # My old version of what I thought this should do 
  # def handle_response(spots, board) 
  #   puts spots.length() > 0 ? 
  #     "Dag-nabbit! The computer got some right. :-(" : 
  #     "Huzzah! The computer's guess was incorrect!."; 
  # end 

  # New version of how the computer should handle the response 
  def handle_response(letter, spots) 
    if spots.length() == 0 
      @dictionary.reject!() { |word| word.include?(letter) }; 
    else 
      spots.each() do |spot| 
        @dictionary.reject!() do |word| 
          # I have a feeling that the 2nd part of the OR statement might be giving me false positives 
          # I think I might need to move it out into a separate "if" chunk/block to handle things correctly 
          (word[spot] != letter) || (word.split('').count() { |x| x == letter } != spots.length()); 
        end 
      end 
    end 
  end 
end 


# --------------------------------------------- 
# SETTING UP THE GAME TO RUN 
# --------------------------------------------- 

# Version 1.0
# if __FILE__ == $PROGRAM_NAME 
#   puts 
#   puts 'WELCOME TO HANGMAN!'; 
  
#   puts 
#   puts 'Player 1, please enter your name: '; 
#   p1 = HumanPlayer.new(gets.chomp().capitalize()); 

#   puts 
#   puts 'Would you like to play a 2nd real human, person, type being?'; 
#   puts '(e.g. Y or N)'; 
#   answer = gets.chomp().upcase(); 

#   if answer == 'Y' 
#     puts 
#     puts 'Player 2, please enter your name: '; 
#     p2 = HumanPlayer.new(gets.chomp()); 
#   else 
#     dict = ['bueller','sloane','cameron','rooney']; 
#     p2 = ComputerPlayer.new(dict); 
#   end 

#   players = { referee: p1, guesser: p2 }; 

#   game = Hangman.new(players); 
#   game.play(); 
# end 


# ———————————————————————————————————————————————————————————————————— 
# Version 2
if __FILE__ == $PROGRAM_NAME 
  puts 
  puts 'WELCOME TO HANGMAN!'; 
  
  puts 
  puts 'Should Player 1 be human (H) or computer (C)?'; 
  player_type = gets.chomp().upcase(); 

  if player_type == 'H' 
    puts 'Player 1, please enter your name:'; 
    p1 = HumanPlayer.new(gets.chomp().capitalize()); 
  elsif player_type == 'C' 
    dict = ['bueller','sloane','cameron','rooney','car','class']; 
    p1 = ComputerPlayer.new(dict); 
  else 
    # I prolly need to make this chunk a method so I can recursively call itself 
    # for when an invalid answer is entered 
    puts 'Please enter a valid player type.'; 
  end 

  puts 
  puts 'Should they play a 2nd real life, human, person, type being?'; 
  puts '(e.g. Y or N)'; 
  answer = gets.chomp().upcase(); 

  if answer == 'Y' 
    puts 
    puts 'Player 2, please enter your name: '; 
    p2 = HumanPlayer.new(gets.chomp().capitalize()); 
  else 
    dict = ['ekko','ashe','bard','quinn','fortune', 'graves']; 
    p2 = ComputerPlayer.new(dict); 
  end 

  puts 
  puts 'Who do you want to be referee? Player 1 or Player 2?'; 
  puts '(please enter 1 or 2)'; 
  decision = gets.chomp().to_i(); 

  if decision == 1 
    ref = p1; 
    guess = p2; 
  elsif decision == 2 
    ref = p2; 
    guess = p1; 
  else 
    # I prolly need to make this chunk a method so I can recursively call itself 
    # for when an invalid answer is entered 
    puts 'Please enter a valid player number.'; 
  end 

  players = { referee: ref, guesser: guess }; 

  game = Hangman.new(players); 
  game.play(); 
end 

# FINAL NOTES: 
# Overall, with a comp ref & a human guesser, everything works smoothly 

# With a human as a ref & a comp guesser, there are some pitfalls/bugs: if the human/user enters wrong information when "checking the guess" 
  # it causes the game to "crash" because of a "NoMethodError" on a NilClass 

# With two comps playing, I've had mixed results 
  # initially, it ran smoothly and the game was over in a breeze 
  # however, subsequent runs/tests are bringing up "NoMethodError"'s on NilClass 
  # Also, I'd like to get the "default_dict" method working to read in words from an external file 
  # But I'm not too familiar with using the File class just yet 
