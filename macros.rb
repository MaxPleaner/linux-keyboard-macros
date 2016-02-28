# stdlib dependencies
require 'pty' # pseudo-terminal

# ./lib dependencies
require_relative './lib/run_with_timeout.rb'

# gems
require 'active_support/all'
require 'colored'

# Overwrite nil.to_sym to return :nil instead of raising NoMethodError
# This is useful with Object#try
class NilClass; def to_sym; :nil; end; end;

# Test sudo access
puts "testing sudo access with 'sudo pwd'"
sudo_access = run_with_timeout(command="sudo pwd", timeout=0.5, tick=0.1)
if sudo_access.blank?
  puts "Error".red
  puts "configure the 'sudo' command for the current user to not require a password input"
  puts "This can be done by simply running 'sudo pwd' because 'sudo' automatically saves passwords for 5 minutes."
  puts "If your visudo configuration doesn't remember password, this wont work"
  exit
end

# this is passed to Macros.shell_thread(cmd) when the script is run (see end of file)
# evtest produces a streaming log of system events
# '3' is echoed to the process to select 'keyboard' events
EventsStreamShellCommand = "(echo '3';) | sudo -S evtest" # The -S is necessary here

# Mapping of phrases => events
# The Macros class sends it keys using CommandParser.add_key(key)
class CommandParser
  ParserInstance = CommandParser.new
  @@max_phrase_length = 15
  @@current_phrase = ""
  @@macro_method_mappings = {
    # key: the macro trigger phrase
    # val: a CommandParser instance method
    "hello world" => "hello_world",
    "text entry" => "test_text_entry"
  }
  def self.add_key(key)
    system "clear"
    (@@current_phrase[0] = '') unless @@current_phrase.length < @@max_phrase_length
    @@current_phrase << key
    matching_method = @@macro_method_mappings.select { |macro_name, result_cmd|
      @@current_phrase.include?(macro_name) &&\
      @@current_phrase.end_with?(macro_name) # only match phrase at EOL
    }.values.first
    puts "#{"matching method".green}: #{matching_method.to_s}" if matching_method
    puts "#{"current phrase".yellow}: #{@@current_phrase}"
    CommandParser::ParserInstance.try(matching_method.to_sym)
    print_available_methods
  end
  def self.print_available_methods
    puts "Available_methods: ".green
    puts @@macro_method_mappings.keys.map { |key| "  #{key}\n"}.join + "\n"
  end
  def initialize(options={})
    puts "Initializing CommandParser".white_on_black
  end
  def hello_world
    `chromium-browser http://artoo.io`
  end
  def test_text_entry
    'hello world'.chars.each { |char| `xdotool key #{char.eql?(' ') ? 'space' : char}` }
  end
end

class Macros
  def self.process_line(line)
    # Uses regex-parsing to find which key was pressed
    # For example, the "C" key would be selected from the string "code 46 (KEY_C), value 1"
    key_info = line.scan(/KEY_.+\)/).flatten.first
    return if key_info.blank? || line.include?("value 0")
    parsed_key_info =  key_info.split("KEY_")[-1]
                               .split(")")[0]
                               .downcase
    parsed_key_info = " " if parsed_key_info == "space"
    return unless parsed_key_info.in?(['a'.upto('z').to_a, " ", "@"].flatten)
    CommandParser.add_key(parsed_key_info)
  end
  def self.shell_thread(cmd)
    begin
    PTY.spawn( cmd ) do |stdout, stdin, pid|
      begin
        stdout.each { |line| Macros.process_line(line) }
      rescue Errno::EIO
        puts "Errno:EIO error, but this probably just means " +
              "that the process has finished giving output"
      end
    end
    rescue PTY::ChildExited
      puts "The child process exited!"
    end
  end
end

# Run this block when the script is executed
if __FILE__ == $0
  begin
    Macros.shell_thread(EventsStreamShellCommand)
  rescue StandardError => e
    puts "error".red
    puts e, e.message, e.backtrace
  end
end

