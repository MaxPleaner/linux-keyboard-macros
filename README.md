### **Keyboard Macros**

- Summary
  - This uses the `evtest` linux program to get a stream of all keyboard events.
  - The events are parsed using Regex and keypresses are tracked.
  - Events can be programmed to fire using `xdotool` when certain phrases are entered
  - This program evolved from my [artoo-keyboard-macros](https://github.com/maxpleaner/artoo-keyboard-macros) project.
  - The reason for redoing it was that artoo-keyboard doesnt support global listeners [link to github issue](https://github.com/hybridgroup/artoo-keyboard/issues/6)
  - [`pty`](http://ruby-doc.org/stdlib-2.2.3/libdoc/pty/rdoc/PTY.html) from Ruby's stdlib is used for the streaming I/O 

-  How to run
  - How to run: __`ruby macros.rb`__
  - Then type anywhere (not just the terminal window) and notice how the text is captured.
  - A list of available macros (and the name of the Ruby method they trigger) can be seen in the terminal when the
    program is running. 
    - try typing `hello world`, which will open artoo.io in `chromium-browser`,
    or `text entry`, which will type 'hello world' under the cursor. 

- Code organization
  - All the code besides `Gemfile` is in `macros.rb`. Run `bundle` to install `activesupport`, the only dependency. 
  - To add a macro:
    1. create an instance method in `CommandParser` (this is the event that is fired)
    2. map the event to a phrase by adding an entry to `@@macro_method_mappings` in `CommandParser`
    3. Note that there is currently only support for 0-9, a-z (lowercase), and space characters in macro triggers
    
- Triggering key presses
  - **How to program a macro to enter text for me?**
  - There are three helper methods:
    - `CommandParser.trigger_deletes(n)` will trigger the 'BackSpace' key n times using `xdotool`.
    - `CommandParser.trigger_keystrokes(string)` will translate the string into `xdotool` instructions and enter the keystrokes.
    - `CommandParser.trigger_for(method_name)` looks inside `@@macro_method_mappings` to find the macro string which a particular
    ruby method (event). This is used in conjunction with `trigger_deletes` to easily delete the trigger text. i.e.: 
    `CommandParser.trigger_deletes(CommandParser.trigger_for("my_ruby_method"))` will delete whatever text was used to trigger the method.   

- Note on sudo
  - This script uses sudo when calling `evtest` (which requires it)
  - The script **does not** ask for sudo, and will just hang if the current user needs to use a password to use sudo. 
  - For just testing this out one can run a command like `sudo pwd` and then run `macros.rb` in the next 5 minutes.
  - The  timeout of `sudo` can be increased by running `sudo visudo` and changing the value of `Defaults:user_name timestamp_timeout`.
  - Alternatively, the script can be run like `sudo ruby macros.rb`. This requires sudo's ruby version (1.9.3, perhaps) 
    to have all the gems installed, and additionally, many commands like `chromium-browser` won't work when called by sudo. 