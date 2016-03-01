#!/usr/bin/env ruby

# ---------------------------------------------------------
# Note that 'require' statements are further down in the program,
# in the "Environment / dependency configuration" section
# ---------------------------------------------------------

# ---------------------------------------------------------
## Command Parser class
# Mapping of phrases => events
# The Macros class sends it keys using CommandParser.add_key(key)
# @@macro_method_mappings maps macro-strings to CommandParser instance methods
# ---------------------------------------------------------

class CommandParser

# ---------------------------------------------------------
# Macro triggers
# ---------------------------------------------------------

# Declare the max-length for macro names,
# i.e. when to start shifting characters
@@max_phrase_length = 15

# Declarations of 'phrase' => 'event' mappings
  # Add something here when creating a new macro
  @@macro_method_mappings = {
    # key: the macro trigger phrase
    # val: a CommandParser instance method
    "hello world" => "hello_world",
    "text entry" => "test_text_entry",
    "@@cover letter" => "cover_letter"
  }  

# ---------------------------------------------------------
# CommandParser instance methods (macro events):
# ---------------------------------------------------------

  def hello_world
    self.class.trigger_deletes(self.class.trigger_for("hello_world").length)
    `chromium-browser http://artoo.io`
  end

  def test_text_entry
    self.class.trigger_deletes(self.class.trigger_for("test_text_entry").length)
    self.class.trigger_keystrokes("hello world")
    # these triggered keystrokes are not scanned for additional macros,
    # and even though "hello world" is a macro phrase,
    # the hello_world method is not called
  end

  def cover_letter
    self.class.trigger_deletes(self.class.trigger_for("cover_letter").length)
    `subl /home/max/Desktop/maxp-site/public/cover-letter.txt`
  end

# ---------------------------------------------------------
# CommandParser configuration
# ---------------------------------------------------------

  # Class methods call instance methods through the ParserInstance constant
  ParserInstance = CommandParser.new
  
  # Add keystrokes to a current_phrase string
  # This is scanned for matching phrases
  @@current_phrase = ""
  
  # Store a string detailing all available methods
  # It is printed repeatedly and doensn't need to be reconstructed.
  @@available_methods_string = @@macro_method_mappings.map do |k,v|
    "  #{k.ljust(@@max_phrase_length)} => #{v}\n"
  end.join + "\n"

# ---------------------------------------------------------
# CommandParser class methods
# ---------------------------------------------------------

  # Adds a key to @@current_phrase and scans it for matching phrases.
  # Calls events for matching phrases.
  def self.add_key(key)
    # Clear the terminal screen each time a key is typed.
    system "clear"
    # Shift a character if the phrase is at max capacity
    (@@current_phrase[0] = '') unless @@current_phrase.length < @@max_phrase_length
    # Add the new character
    @@current_phrase << key
    # Find matching methods
    matching_method = @@macro_method_mappings.select { |macro_name, result_cmd|
      @@current_phrase.include?(macro_name) &&\
      @@current_phrase.end_with?(macro_name) # only match phrase at EOL
    }.values.first
    puts "#{"matching method".green}: #{matching_method.to_s}" if matching_method
    puts "#{"current phrase".yellow}: #{@@current_phrase}"
    # Run event for a matched phrase, if one was found
    CommandParser::ParserInstance.try(matching_method.to_sym)
    # Print available methods each time a key is typed.
    print_available_methods
  end

  def self.print_available_methods
    puts "#{"Available_methods: \n".green}#{"  #{"macro_name".ljust(@@max_phrase_length)} => event_method".red} "
    puts "  " + ("-" * @@max_phrase_length * 2)
    puts @@available_methods_string
  end


  def self.trigger_keystrokes(string='')
    # supports 0-9, a-z (lowercase), '/', ':', ';', '@', '&', '?', and '.'
    # This is so that email addresses / urls can be printed.
    # Note that triggered keystrokes are not added to @@current_phrase
    # and will not trigger subsequent macro events.
    (string || '').chars.each do |char|
      translated_char = case char
      when ' '
        'space'
      when '/'
        'slash'
      when ';'
        'semicolon'
      when '.'
        'period'
      else
        char 
      end
      if translated_char.eql?('@')
        `xdotool keydown shift `
        `xdotool key 2`
        `xdotool keyup shift`
      elsif translated_char.eql?(":")
        `xdotool keydown shift`
        `xdotool key semicolon`
        `xdotool keyup shift` 
      elsif translated_char.eql?('?')
        `xdotool keydown shift`
        `xdotool key slash`
        `xdotool keyup shift` 
      elsif translated_char.include?('&')
        `xdotool keydown shift`
        `xdotool key 7`
        `xdotool keyup shift` 
      else
        `xdotool key #{translated_char}`
      end
    end
  end

  def self.trigger_deletes(n=0)
    n.times { `xdotool key BackSpace` }
  end

  def self.trigger_for(method_name='')
    @@macro_method_mappings.key(method_name) # lookup key by val
  end

  def initialize(options={})
    puts "Initializing CommandParser".white_on_black
  end

end

# The Macros class continuously reads from evtest output, parses for keystrokes and 
# sends these to CommandParser.
class Macros
  # use Macros.shell_thread to continuously read from a non-exiting shell process.
  def self.shell_thread(cmd)
    # credit for this method goes to http://stackoverflow.com/a/1162850/2981429
    begin
    PTY.spawn( cmd ) do |stdout, stdin, pid|
      begin
        stdout.each { |line| Macros.process_line(line) } # send each output line to Macros.process_line
      rescue Errno::EIO
        puts "Errno:EIO error, but this probably just means " +
              "that the process has finished giving output"
      end
    end
    rescue PTY::ChildExited
      puts "The child process exited!"
    end
  end
  # Parses a evtest output line for keystrokes. Sends these to CommandParser
  def self.process_line(line)
    # Uses regex-parsing to find which key was pressed
    # For example, the "C" key would be selected from the string "code 46 (KEY_C), value 1"
    key_info = line.scan(/KEY_.+\)/).flatten.first
    # Ignore output lines that don't contain "KEY_", these are irrelevant
    return if key_info.blank? || line.include?("value 0") # value 0 denotes key-up. Ignore these. Only accept key-down.
    # parse "c" from "KEY_C)"
    parsed_key_info =  key_info.split("KEY_")[-1]
                               .split(")")[0]
                               .downcase
    # convert the 'space' string into ' ' which is what macro trigger phrases use.
    parsed_key_info = " " if parsed_key_info == "space"
    # only accept 1-9, a-z, and ' ' for now.
    return unless parsed_key_info.in?(['0'.upto('9').to_a, 'a'.upto('z').to_a, " "].flatten)
    # If the method gets this far, the key is valid.
    # Send the key to command parser.
    CommandParser.add_key(parsed_key_info)
  end
end

# --------------
# Environment / dependency configuration
# --------------

## stdlib dependencies
require 'pty' # pseudo-terminal

## local file dependencies
require_relative './lib/run_with_timeout.rb'

## gems
require 'active_support/all'
require 'colored'

## Overwrite nil.to_sym to return :nil instead of raising NoMethodError
# This is useful with Object#try
class NilClass; def to_sym; :nil; end; end;

## Test sudo access
puts "testing sudo access with 'sudo pwd'"
sudo_access = run_with_timeout(command="sudo pwd", timeout=0.5, tick=0.1)
if sudo_access.blank?
  puts "Error".red
  puts "configure the 'sudo' command for the current user to not require a password input"
  puts "This can be done by simply running 'sudo pwd' because 'sudo' automatically saves passwords for 5 minutes."
  puts "If your visudo configuration doesn't remember password, this wont work"
  exit
end

## Define the command used to get input keystrokes
# this is passed to Macros.shell_thread(cmd) when the script is run (see end of file)
# evtest produces a streaming log of system events
# '3' is echoed to the process to select 'keyboard' events
EventsStreamShellCommand = "(echo '3';) | sudo -S evtest" # The -S is necessary here to used saved sudo password.

# ---------------------
# Script execution
# ---------------------

# Run this block when the script is executed
if __FILE__ == $0
    Macros.shell_thread(EventsStreamShellCommand)
end

