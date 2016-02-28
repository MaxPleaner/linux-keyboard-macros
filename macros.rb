# stdlib dependencies
require 'pty'

# gems
require 'active_support/all'
require 'byebug'

# Overwrite nil.to_sym to return :nil instead of raising NoMethodError
# This is useful with Object#try
class NilClass; def to_sym; :nil; end; end;

# this is passed to Macros.shell_thread(cmd) when the script is run (see end of file)
# evtest produces a streaming log of system events
# '3' is echoed to the process to select 'keyboard' events
EventsStreamShellCommand = "(echo '3';) | sudo -S evtest"

# Mapping of phrases => events
# The Macros class sends it keys using CommandParser.add_key(key)
class CommandParser
  ParserInstance = CommandParser.new
  @@max_phrase_length = 15
  @@current_phrase = ""
  @@macro_method_mappings = {
    # "macro_name" => "Macros class method"
    "hello world" => "hello_world"
  }
  def self.add_key(key)
    system "clear"
    (@@current_phrase[0] = '') unless @@current_phrase.length < @@max_phrase_length
    @@current_phrase << key
    matching_method = @@macro_method_mappings.select { |macro_name, result_cmd|
      @@current_phrase.include?(macro_name) &&\
      @@current_phrase.end_with?(macro_name) # only match phrase at EOL
    }.values.first
    puts "matching method: #{matching_method.to_s}" if matching_method
    puts "current phrase: #{@@current_phrase}"
    CommandParser::ParserInstance.try(matching_method.to_sym)
  end
  def initialize(options={})
  end
  def hello_world
    `chromium-browser http://artoo.io`
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
    return unless parsed_key_info.in?(['a'.upto('z').to_a, " "].flatten)
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
  Macros.shell_thread(EventsStreamShellCommand)
end

