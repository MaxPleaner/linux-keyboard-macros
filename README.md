Keyboard Macros

- This uses the `evtest` linux program to get a stream of all keyboard events.
- The events are parsed using Regex and keypresses are tracked.
- Events can be programmed to fire when certain phrases are entered.

- This program evolved from my [artoo-keyboard-macros](https://github.com/maxpleaner/artoo-keyboard-macros) project.
- The reason for redoing it was that artoo-keyboard doesnt support global listeners [link to github issue](https://github.com/hybridgroup/artoo-keyboard/issues/6)

- The only macro pre-programmed is "hello world", which when typed will open the [artoo.io](artoo.io) site using
`chromium-browser`. 

- All the code besides `Gemfile` is in `macros.rb`. Run `bundle` to install `activesupport`, the only dependency. 
- To add a macro:
  1. create an instance method in `CommandParser` (this is the event that is fired)
  2. map the event to a phrase by adding an entry to `@@macro_method_mappings` in `CommandParser`

- How to run: __`ruby macros.rb`__
- Then type anywhere (not just the terminal window) and notice how the text is captured.
- [`pty`](http://ruby-doc.org/stdlib-2.2.3/libdoc/pty/rdoc/PTY.html) from Ruby's stdlib is used for the streaming I/O 
- Try typing hello world somewhere

- ** How to program a macro to enter text for me? **
- Use the `xdotool` in a event method like `'hello world'.chars.each { |char| \`kdotool key #{char}\` } `
- This triggers keyboard presses for each desired character.
- Note that this doesn't automatically delete the trigger phrase, but the BackSpace key can be triggered in the event. 

- **Note on sudo**
- This script uses sudo under the hood when calling `evtest` (which requires it)
- The script **does not** ask for sudo, and will just hang if the current user needs to use a password to use sudo. 
- For just testing this out one can run a command like `sudo pwd` and then run `macros.rb` in the next 5 minutes.
- The  timeout of `sudo` can be increased by running `sudo visudo` and changing the value of `Defaults:user_name timestamp_timeout`.
- Alternatively, the script can be run like `sudo ruby macros.rb`. This requires sudo's ruby version (1.9.3, perhaps) 
  to have all the gems installed, and additionally, many commands like `chromium-browser` won't work when called by sudo. 