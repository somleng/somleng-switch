require "bundler"

Bundler.require(:default, :development)

require File.expand_path("config/environment", __dir__)
require "adhearsion/tasks"

require_relative "lib/encrypted_credentials"

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)

  task default: :spec
rescue LoadError
  # no rspec available
end

namespace :credentials do
  task :edit do
    EncryptedCredentials::EncryptedFile.new.edit
  end
end
