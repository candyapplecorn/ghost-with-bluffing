# Helper method: Prompt. Takes a text question, asks for a response and returns it
def prompt question
	prefix = "> "
	printf("%s\n%s", question, prefix)
	gets.chomp
end


class Game
	def initialize
		# 1. Get the dictionary path. Default is set, just hit enter to accept
		@DICTIONARY_PATH = "dictionary.txt"
		#puts "Dictionary path is #{@DICTIONARY_PATH}. Press enter to accept, or enter a dictionary filename."
		#@DICTIONARY_PATH = (lambda {|response| @DICTIONARY_PATH = response if (not (response =~ //))}).call(gets.chomp)
		

		# 2. Bluffing
		#puts "Bluffing is OFF. Press enter to accept, or enter 'ON' to enable bluffing."
		#@bluffing = !!(gets.chomp =~ /on/i)
		@bluffing = !!((prompt "Bluffing is OFF. Press enter to accept, or enter 'ON' to enable bluffing.") =~ /on/i)
		# 3. Get the players. This will execute code in Player_group's constructor
		@player_group = Player_Group.new
	end

	def play_round
		puts `clear`
		puts "Beginning a new round"
		# 1. make a new fragment
		@frag = Fragment.new(@DICTIONARY_PATH, @bluffing)

		while (@bluffing ? true : (not @frag.is_word))
		# 	3. get next player (playergroup.next)
			@player_group.next

			puts `clear`
			display_scores
			#puts "It is #{@player_group.current_player.name}'s turn."
			#puts "================\n"

		#	3. b - if bluffing, then ask if current player would like to challenge 
			if @bluffing and @frag.letters.length >= 3 then
				break if challenge
			else
		#	4. get a valid?(bluffing) letter from the current player
				get_letter
			end

			if not @bluffing and @frag.is_word then
				puts "#{@frag.letters.upcase} is a word! #{@player_group.current_player.name} gets a letter."
				@player_group.current_player.add_letter
				break
			end
		end
		# round ends; display scores 
		display_scores
		puts "Press ENTER to continue..."
		gets
	end

	def challenge
		chal = prompt "The current fragment is '#{@frag.letters.upcase}'. Type 'chal' to challenge, or enter a letter"
		return false if chal == ""

		if chal.length == 1 then
			@frag.add_letter chal
			return false
		end

		puts "#{@player_group.current_player.name} challenges #{@player_group.previous_player.name}"

		# ask current player if the frag is a word. if says yes, and is, previous gets a letter, end round.
		bool = prompt "#{@player_group.current_player.name}, is #{@frag.letters.upcase} a word? Enter Y[es], or enter either N[o] or nothing"
		if bool =~ /^y/i and @frag.is_word then
			puts "#{@frag.letters.upcase} is a word. #{@player_group.previous_player.name} gets a letter."
			@player_group.previous_player.add_letter
			return true
		elsif bool =~ /^y/i and not @frag.is_word then
			puts "#{@frag.letters.upcase} is NOT a word. #{@player_group.current_player.name} gets a letter."
			@player_group.current_player.add_letter
			return true
		end


		# ask previous player to enter a word which begins with fragment
		word = prompt "Enter a valid word #{@player_group.previous_player.name}, which begins with #{@frag.letters.upcase}"

		challenge_frag = Fragment.new(@DICTIONARY_PATH, @bluffing)
		challenge_frag.letters = word
		
		if challenge_frag.is_word and challenge_frag.letters =~ Regexp.new("^" + @frag.letters, "i")
			puts "#{challenge_frag.letters.upcase} is a valid word. #{@player_group.current_player.name} gets a letter"
			@player_group.current_player.add_letter
		else
			puts "#{challenge_frag.letters.upcase} is NOT a valid word. #{@player_group.previous_player.name} gets a letter"
			@player_group.previous_player.add_letter
		end
		puts "Press ENTER to continue..."
		gets
		true
	end

	def get_letter (letter = "")
		loop do
			if (letter == "")
				letter = prompt "The current fragment is '#{@frag.letters.upcase}'.\nPlease enter a letter, #{@player_group.current_player.name}."
			end	

			ok = @frag.add_letter letter

			letter = ""
			break if ok
		end
	end

	def run
		play_round while not @player_group.winner?

		# announce the winning player, and scores
		puts `clear`
		display_scores
		puts "\n\n#{@player_group.winner?.name} wins!\n\n"
	end

	def display_scores
		puts "\n== Game Score =="
		row = lambda {|player|
			if @player_group.current_player.name == player.name then
				printf("%s", "-->")
			else
				printf("%s", "   ")
			end
				
			printf("%s\t%s\n", player.name, player.get_record)
		}
		@player_group.players.sort{|x, y| x.name <=> y.name }.each do |player|
			row.call(player)
		end

		puts "================"
		puts "=== Fragment ==="
		printf("   %s\n", @frag.letters.upcase)
		puts "================"
	end
end

class Player_Group
	attr_accessor :players
	def initialize
		@players = []
		get_players
	end

	def get_players
		loop do
			response = prompt "Enter a player's name to add a player, or 'done' to start playing"

			if response =~ /done/i and @players.length < 2
				puts "At least two players must register in order to play"
				next
			elsif response =~ /done/i and @players.length >= 2
				break
			else
				@players.push Player.new(response[0].upcase + response.slice(1, response.length).downcase)
				puts (@players.last.name + " has joined the game!")
			end
		end
		puts @players.map{|p| p.name}.join(", ") + " will begin Ghost!"
	end

	def next
		loop do # a do while loop
			cycle @players
			break if @players[0].is_alive	
		end
		@players.first
	end
	
	def current_player
		@players.first
	end

	def previous_player
		@players.reverse[@players.reverse.index {|player| player.is_alive }]
	end

	def cycle list
		list.unshift list.pop
	end

	# returns the winning player or false if no winenrs
	def winner?
		playing = @players.select do |player|
			player.is_alive
		end

		playing.length <= 1 ? playing[0] : false
	end
end

class Player
	attr_accessor :name
	attr_accessor :losses

	def initialize(name)
		@name = name
	 	@losses = 0
	end	

	def add_letter 
		@losses += 1
	end

	def get_record
		"GHOST".slice(0, @losses)
	end

	def is_alive
		@losses < 5
	end	

end

class Fragment
	attr_accessor :letters

 	def initialize (dictionary_path, bluffing = false)
		@letters = ""
		@bluffing = bluffing
		@dict = Dictionary.new dictionary_path 
	end

 	def add_letter letter
		if letter.length != 1
			puts "#{letter} isn't valid; entry must be a single letter."
			return false
		end

		if @bluffing
			@letters += letter
			return true
		elsif (is_valid( letter ))
			@letters += letter
			return true
		end	
		false
	end

	def is_word
		return @dict.valid(@letters + "$")
	end

	# if passed a letter, returns true if the attempted fragment is a valid beginning
	def is_valid(letter = "")
		return @dict.valid (@letters + letter)
	end

end

# Dictionary contains a filename and, given the beginning of a string,
# returns true if a word in the file begins with that string
class Dictionary
 	def initialize filename
		@fn = filename
	end

	def valid (beginning = "")
		File.foreach(@fn) do |line = ""|
			if line =~ Regexp.new("^" + beginning, "i") then
				return true
			end
		end
		false
	end
end

# Run the game
Game.new.run
