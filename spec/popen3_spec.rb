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
        puts "OK"
        EM.stop
      end
      handler.errback do |err_code|
        fail "WTF! #{err_code}"
        EM.stop
      end
      handler.send_data("5\n")
    end
  end
end
