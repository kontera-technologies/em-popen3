# --
# Author:: stask
# inspired by http://pastebin.com/TLgVF8GZ

require 'open3'

module EventMachine

  # EM::popen3 is used to launch given command and capture the stdin, stdout and stderr streams.
  #
  # Example:
  # EM.run do
  #   p = EM.popen3('ls', {
  #                         :stdout => Proc.new { |data| puts "stdout: #{data}" },
  #                         :stderr => Proc.new { |data| puts "stderr: #{data}" }
  #                       })
  #   p.callback do
  #     puts "All good"
  #   end
  #   p.errback do |err_code|
  #     puts "Error: #{err_code}"
  #   end
  # end
  #
  # It returns a deferrable object
  def self.popen3(cmd, stream_callbacks)
    raise ArgumentError, "stream_callbacks must be specified" unless stream_callbacks
    raise ArgumentError, ":stdout callback must be specified" unless stream_callbacks[:stdout].is_a?(Proc)
    raise ArgumentError, ":stderr callback must be specified" unless stream_callbacks[:stderr].is_a?(Proc)

    POpen3::Wrapper.new(cmd, stream_callbacks)
  end

  private
  module POpen3

    class Wrapper
      include EM::Deferrable
      attr_accessor :pipes, :stream_callbacks

      def initialize(cmd, stream_callbacks)
        @pipes = {}
        @stream_callbacks = stream_callbacks
        stdin, @stdout, @stderr, @wait_thr = Open3.popen3(cmd)
        EM.attach(stdin, Handler, self, :stdin)
        EM.attach(@stdout, OutHandler, self, :stdout)
        EM.attach(@stderr, OutHandler, self, :stderr)
      end

      def send_data(data)
        pipes[:stdin].send_data(data) if pipes.has_key?(:stdin)
      end

      def kill(signal='TERM', wait=false)
        Process.kill(signal, @wait_thr.pid)
        @stdout.close
	@stderr.close
	@wait_thr.value if wait
      end

      def unbind(name)
        pipes.delete(name)
        if pipes.empty?
          err_code = @wait_thr.value
          err_code == 0 ? succeed : fail(err_code)
        end
      end
    end

    class Handler < EM::Connection
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
        @parent.stream_callbacks[@name].call(data) if @parent.stream_callbacks.has_key?(@name)
      end
    end
  end
end
