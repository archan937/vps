class String

  COLORS = {
    :red     => 31,
    :green   => 32,
    :yellow  => 33,
    :blue    => 34,
    :magenta => 35,
    :cyan    => 36,
    :white   => 39,
    :gray    => 90
  }

  COLORS.keys.each do |color|
    define_method color do
      colorize color
    end
  end

  def indent(n, string = " ")
    split("\n").collect do |line|
      line.empty? ? line : "#{string * n}#{line}"
    end.join("\n")
  end

private

  def colorize(color)
    color = COLORS[color]
    "\033[0;#{color}m#{self}\033[0m"
  end

end
