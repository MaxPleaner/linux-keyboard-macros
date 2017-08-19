

## **Keyboard Macros**

_usage gif_

![usage_gif](macros.gif)

This uses the evtest linux program to get a stream of all keyboard events.

The events are parsed using Regex and keypresses are tracked.

Phrases are mapped to Ruby methods which are called when the phrase is typed anywhere.

Text can be programmatically added / removed under the cursor using xdotool helper methods.

This program evolved from my [artoo-keyboard-macros](https://github.com/maxpleaner/artoo-keyboard-macros) project.
The reason for redoing it was that artoo-keyboard doesnt support global listeners [link to github issue](https://github.com/hybridgroup/artoo-keyboard/issues/6)

[pty](http://ruby-doc.org/stdlib-2.2.3/libdoc/pty/rdoc/PTY.html) from Ruby's stdlib is used for the streaming I/O 

### Installation

first install dependencies:

- `sudo apt-get install xdotool evtest`

Then clone the repo, `cd` in and run `bundle install`.

**_note_: if this fails try removing Gemfile.lock first**

Then run the program: `./macros_server.rb`

Type anywhere (not just the terminal window) and notice how the text is captured.

A list of available macros (and the name of the Ruby method they trigger) can be seen in the terminal when the
program is running. 

try typing `hello world`, which will open artoo.io in `chromium-browser`
or type `text entry`, which will type 'hello world' under the cursor.

Note that the programmatically triggered keystrokes are **not** searched for
additional macros. 

### How to add a macro:

1. create an instance method in `CommandParser` (this is the event that is fired)
2. map the event to a phrase by adding an entry to `@@macro_method_mappings` in `CommandParser`
3. Note that characters supported in macro trigger strings are: `0-9, a-z (lowercase), and whitespace.`
    
###  How to trigger key presses / deletes

**How to program a macro to enter text?**

There are three helper methods:

- `CommandParser.trigger_deletes(n)` will trigger the 'BackSpace' key n times using `xdotool`.
- `CommandParser.trigger_keystrokes(string)` will translate the string into `xdotool` instructions and enter the keystrokes.
- `CommandParser.trigger_for(method_name)` looks inside `@@macro_method_mappings` to find the macro string which triggers a particular
    ruby method (event). This is used in conjunction with `trigger_deletes` to delete the trigger text. i.e.: 
    `CommandParser.trigger_deletes(CommandParser.trigger_for("my_ruby_method").length)` will delete whatever text was used to trigger the method.
- More characters are accepted when triggering keypresses than when
  defining macro phrases. In addition to supporting `0-9, 'a'-'z' and whitespace` like macro phrases,
  triggered keypresses can also include `'/', ':', ';', '@', '?', '&', and '.'`. This is so that urls and email addresses can be
  supported. 

### Caveat regarding sudo

- If the script errors after "checking for sudo access", try `sudo bundle` and `sudo ruby macros_server.rb` 

### Contributing / todos

The main thing I want to do is add a macros YAML file

Also:

1. Being able to trigger any keystroes, not just `0-9, 'a'-'z', whitespace, '/', ':', ';', '@', '?', '&', and '.'`. This could be done by editing `CommandParser.trigger_keystrokes`.
3. Supporting more characters in macro phrases, including single-keypress named characters like `,./';[]=-` and multi-keypress characters like `!@#$%^&*()_+?><:"{}`.
3. Supporting variables in macros, i.e. `email maxpleaner@gmail.com` could use the email address as a varaible.
