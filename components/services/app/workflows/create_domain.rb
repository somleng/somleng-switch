class CreateDomain < ApplicationWorkflow
  attr_reader :domain

  def initialize(domain:)
    @domain = domain
  end

  def call
    result, = ManageDomains.new(domains: [ domain ]).create_domains
    {
      domain: result
    }
  end
end
