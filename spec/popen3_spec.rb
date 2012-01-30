$:.push File.expand_path('../../lib', __FILE__)
$:.push File.expand_path('../', __FILE__)
require 'helper'

describe EventMachine::POpen3 do
  it "smokes" do
    cmd = <<EOS
ruby -e "\\$stdout.sync = true; \\$stderr.sync=true; gets.to_i.times { |i| \\$stdout.puts i+1; \\$stderr.puts i+1; }"
EOS
    stdout_capture = stderr_capture = ''
    EM.run do
      handler = EM.popen3(
        cmd,
        :stdout => Proc.new { |data| stdout_capture << data },
        :stderr => Proc.new { |data| stderr_capture << data })
      handler.callback do
        5.times do |i|
          stdout_capture.must_match(/^#{i+1}$/)
          stderr_capture.must_match(/^#{i+1}$/)
        end
        EM.stop
      end
      handler.errback do |err_code|
        assert(false, "Failed to run command: #{err_code}")
        EM.stop
      end
      handler.send_data("5\n")
    end
  end

  it "can be killed" do
    cmd = <<EOS
/bin/bash -l -c "trap \"echo TERM;echo 0\" SIGINT SIGTERM;sleep 10"
EOS
    stdout_capture = stderr_capture = ''
    EM.run do
      handler = EM.popen3(
        cmd,
        :stdout => Proc.new { |data| stdout_capture << data },
        :stderr => Proc.new { |data| stderr_capture << data }
      )
      handler.callback do
        puts "stopped without error"
        stdout_capture.must_match(/TERM/)
        EM.stop
      end
      handler.errback do |err_code|
        assert(false, "Failed to run command: #{err_code}")
        EM.stop
      end
      EM.add_timer(1) { handler.kill('TERM', true) }
      EM.add_timer(10) { assert(false, 'Failed to kill the damn thing'); EM.stop }
    end
  end
end
