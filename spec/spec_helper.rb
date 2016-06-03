RSpec.configure do |config|
  config.order = "random"
  config.expect_with(:rspec) {|c| c.syntax = :expect }
end

class BogusInstance
  def logger
  end
end
