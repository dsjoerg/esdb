class StackLogger < Logger

  @@showstack = false
  
  def self.stackplz(yesno)
    @@showstack = yesno
  end

  alias :super_add :add
  def add(severity, message = nil, progname = nil, &block)
    if @@showstack
      puts caller
    end
    super_add(severity, message, progname, &block)
  end
end
