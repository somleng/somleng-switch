require_relative "../spec_helper"

RSpec.describe "Handles SQS Message", :opensips do
  it "parrses correctly" do
    payload = {"Records"=>[{"messageId"=>"d7aac474-78d3-4575-b212-360cd8e4ed68", "receiptHandle"=>"AQEBT0UloaQef3wFrQZg9de6kdrgLEYVpSgBnY5LS/tygRFMya4rrqmG6LGKbdIvId0B8WXnzVAIoeF3os3MxEwsjelQmUmwfDHyHmU4MgXSyNDKc6q5hFFS0CZqsJUyQFNuZn6yVYABtnX3ZtYVBSliyMr8a+7L0Pnpz4fXh9HROBv7NGIiAtfL7oQShLDiv6+RZew9gEn5GG88u667cjASkhiBD4mit78F2TT9rQ94njajhMgE5YsFk6Lr9mYfJuc+++8fMjHHaZdOpmegEv0hxmQVxb/kjqOJ7vfTD5g1kq/MxZBsXGGCIMfEYDX0aLdRh8H7wN0IjtdLgps7MoTLwhpkW+ZkkY1gT/vEwToQwyqNIkQtUc8poFxEi9rN6BIGwA7CUbbewNDLU8zyVrjpRXSKj/OE3MpMozU5HafMsY4=", "body"=>"{\"job_class\":\"CreateOpenSIPSPermissionJob\",\"job_args\":[\"54.172.60.4\"]}", "attributes"=>{"ApproximateReceiveCount"=>"1", "SentTimestamp"=>"1660898777291", "SenderId"=>"AROAUXAESSIN35HONUXUE:6cec739180c3448ba4bf1be4b289e94f", "ApproximateFirstReceiveTimestamp"=>"1660898777295"}, "messageAttributes"=>{}, "md5OfBody"=>"bafd968d17e720ccaa31d94555090149", "eventSource"=>"aws:sqs", "eventSourceARN"=>"arn:aws:sqs:ap-southeast-1:324279636507:somleng-switch-staging-services", "awsRegion"=>"ap-southeast-1"}]}
    invoke_lambda(payload:)
  end

  it "adds an address record" do
    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "CreateOpenSIPSPermissionJob",
        "job_args" => ["165.57.32.1"]
      }.to_json
    )

    invoke_lambda(payload:)

    result = address.all
    expect(result.count).to eq(1)
    expect(result[0]).to include(
      ip: "165.57.32.1",
      grp: 0,
      mask: 32,
      port: 0,
      proto: "any"
    )
  end

  it "removes an address message" do
    create_address(ip: "165.57.32.1")

    payload = build_sqs_message_event_payload(
      event_source_arn: "arn:aws:sqs:us-east-2:123456789012:somleng-switch-permissions",
      body: {
        "job_class" => "DeleteOpenSIPSPermissionJob",
        "job_args" => ["165.57.32.1"]
      }.to_json
    )

    invoke_lambda(payload:)

    expect(address.count).to eq(0)
  end

  def address
    opensips_database_connection.table(:address)
  end
end
