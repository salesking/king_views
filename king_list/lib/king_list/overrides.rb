class Object
  # http://www.siaris.net/index.cgi/Programming/LanguageBits/Ruby/DeepClone.rdoc
  def deep_clone
    Marshal::load(Marshal.dump(self))
  end
end