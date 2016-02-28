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

- **Note**
- If the strict just hangs with no output, it may be becauase you are not logged in as sudo.
- `sudo` has a default timeout of `5` minutes, so if you are just testing this out you can run a command like `sudo pwd`
and then run `macros.rb` in the next 5 minutes. The  timeout of `sudo` can be increased by running
`sudo visudo` and changing the value of `Defaults:user_name timestamp_timeout`.
true 
- I know there is a way to pipe password to sudo, something like
`(echo 'my_password'; echo '3';) | ruby macros.rb` but it wasn't working.
Everything except the sudo part worked.  
