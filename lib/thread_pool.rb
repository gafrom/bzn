require 'thread' # for Mutex: Ruby doesn't provide thread-safe arrays out of the box

class ThreadPool
  def initialize(max_threads = 10)
    @pool = SizedQueue.new(max_threads)
    max_threads.times{ @pool << 1 }
    @mutex = Mutex.new
    @running_threads = []
  end

  def run(&block)
    @pool.pop
    @mutex.synchronize do
      @running_threads << Thread.start do
        begin
          block[]
        rescue Exception => e
          puts "Exception: #{e.message}\n#{e.backtrace.join("\n")}"
        ensure
          @pool << 1
        end
      end
    end
  end

  def await_completion
    @running_threads.each &:join
  end
end
