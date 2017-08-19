module MacroDefinitions

  def try_to_call(method_name)
    method_name_sym = method_name&.to_sym
    if method_name_sym && respond_to?(method_name_sym)
      CommandParser.class_exec do
        trigger_deletes(trigger_for(method_name_sym.to_s).length)
      end
      CommandParser.class_exec(&send(method_name_sym))
    end
  end

  def linkedin_url; -> {
    trigger_keystrokes "http://linkedin.com/in/maxpleaner"
  }; end

  def github_url; -> {
    trigger_keystrokes "http://github.com/maxpleaner"
  }; end

  def website_url; -> {
    trigger_keystrokes "http://maxpleaner.com"
  }; end

  def email_url; -> {
    trigger_keystrokes "maxpleaner@gmail.com"
  }; end

  def portfolio_url; -> {
    trigger_keystrokes "http://maxpleaner.github.io"
  }; end

  def cover_letter; -> {
    trigger_keystrokes <<-TXT.strip_heredoc

      Hello,

      My name is Max Pleaner and I'm a web developer in the San Francisco area.
      I've been programming since 2013. Prior to that I worked/studied in politics.
      My strongest languages are Ruby, Javascript, and Elixir.
      I'm confident in many facets of full-stack development, from deployment, APIs,
      and data on the backend to animation, games, build tools, realtime, and 
      reactive frameworks on the frontend. I enjoy constantly learning and strive
      to follow best practices, including testing and documentation. I'm eager to work
      together with a team and have held a few roles in the industry.

      Thanks for your consideration, Max Pleaner
      http://maxpleaner.github.io
      http://maxpleaner.com/resume

    TXT
  }; end

end