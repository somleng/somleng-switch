require_relative "../spec_helper"

RSpec.describe ManageDomains, :client_gateway do
  it "Adds domains" do
    ManageDomains.new(domains: [ "10.1.1.1", "54.251.92.1" ]).create_domains

    result = client_gateway_domains.all
    expect(result.count).to eq(2)
    expect(result[0].fetch(:domain)).to eq("10.1.1.1")
    expect(result[1].fetch(:domain)).to eq("54.251.92.1")
  end

  it "Only adds domains once" do
    create_domain(domain: "10.1.1.1")
    create_domain(domain: "54.251.92.1")

    ManageDomains.new(domains: [ "10.1.1.1", "54.251.92.1" ]).create_domains

    result = client_gateway_domains.all
    expect(result.count).to eq(2)
  end

  it "Deletes domains" do
    create_domain(domain: "10.1.1.1")
    create_domain(domain: "54.251.92.1")

    ManageDomains.new(domains: [ "10.1.1.1", "54.251.92.1" ]).delete_domains

    result = client_gateway_domains.all
    expect(result.count).to eq(0)
  end

  def client_gateway_domains
    client_gateway_database_connection.table(:domain)
  end
end
