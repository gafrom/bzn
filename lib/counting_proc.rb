class CountingProc < Proc
  def initialize
    @count = -1
  end

  def call(*args)
    super(@count+=1, *args)
  end

  def reset
    @count = -1
  end
  alias rewind reset
end
