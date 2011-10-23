# inspired by http://pastebin.com/TLgVF8GZ

require 'open3'

module EventMachine

  def self.popen3(cmd, stream_handlers)
    raise ArgumentError, "stream_handlers must be specified" unless stream_handlers
    raise ArgumentError, ":stdout handler must be specified" unless stream_handlers[:stdout].is_a?(Proc)
    raise ArgumentError, ":stderr handler must be specified" unless stream_handlers[:stderr].is_a?(Proc)

    POpen3Handler.new(cmd, stream_handlers)
  end

  private
  class POpen3Handler
    include Deferrable
    attr_accessor :pipes, :stream_handlers
    
    def initialize(cmd, stream_handlers)
      @pipes = {}
      @stream_handlers = stream_handlers
      stdin, stdout, stderr, @wait_thr = Open3.popen3(cmd)
      EM.attach(stdin, Handler, self, :stdin)
      EM.attach(stdout, OutHandler, self, :stdout)
      EM.attach(stderr, OutHandler, self, :stderr)
    end

    def send_data(data)
      pipes[:stdin].send_data(data) if pipes.has_key?(:stdin)
    end

    def unbind(pipe)
      pipes.delete(pipe)
      if pipes.empty?
        err_code = @wait_thr.value
        err_code == 0 ? succeed : fail(err_code)
      end
    end
  end

  class Handler < Connection
    def initialize(parent, name)
      @parent = parent
      @name   = name

      @parent.pipes[@name] = self
    end

    def unbind
      @parent.unbind(@name)
    end
  end

  class OutHandler < Handler
    def receive_data(data)
      @parent.stream_handlers[@name].call(data)
    end
  end
end
