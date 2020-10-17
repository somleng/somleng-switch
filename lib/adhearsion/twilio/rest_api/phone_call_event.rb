require_relative "resource"
require_relative "../event/recording_started"

class Adhearsion::Twilio::RestApi::PhoneCallEvent < Adhearsion::Twilio::RestApi::Resource
  attr_reader :notify_response

  EVENT_MAPPINGS = {
    Adhearsion::Event::Ringing => {
      :type => :ringing,
      :event_parser => Proc.new { |event| event.parse_ringing_event }
    },
    Adhearsion::Event::Answered => {
      :type => :answered,
      :event_parser => Proc.new { |event| event.parse_answered_event }
    },
    Adhearsion::Event::End => {
      :type => :completed,
      :event_parser => Proc.new { |event| event.parse_end_event }
    },
    Adhearsion::Event::Complete => {
      :event_parser => Proc.new { |event| event.parse_complete_event }
    },
    Adhearsion::Twilio::Event::RecordingStarted => {
      :type => :recording_started,
      :event_parser => Proc.new { |event| event.parse_recording_started_event }
    }
  }

  def notify!
    if configuration.rest_api_phone_call_events_url
      if event_details = parse_event
        log(:info, "Event parsed with details: #{event_details}")
        event_url = phone_call_event_url(:phone_call_id => event_details[:phone_call_id])

        request_body = event_details[:params]

        request_options = {:body => request_body}
        basic_auth, url = extract_auth(event_url)
        request_options.merge!(:basic_auth => basic_auth) if basic_auth.any?

        log(:info, "POSTING to Twilio REST API at: #{url} with options: #{request_options}")

        @notify_response = HTTParty.post(url, request_options)

        log(:info, "Finished POSTING to Twilio REST API with response: #{notify_response.code} and body: #{notify_response.body}")
      else
        log(:info, "No Event Parser or event not parsed for #{event}")
      end
    end
  end

  def parse_ringing_event
    build_request_options(phone_call_id_from_headers, default_request_params)
  end

  def parse_answered_event
    build_request_options(phone_call_id_from_headers, default_request_params)
  end

  def parse_recording_started_event
    build_request_options(
      event.call_id,
      default_request_params.merge(
        :params => compact_hash(event.params)
      )
    )
  end

  def parse_end_event
    build_request_options(
      phone_call_id_from_headers,
      default_request_params.merge(
        :params => compact_hash(
          :sip_term_status => event.headers["variable-sip_term_status"],
          :answer_epoch => event.headers["variable-answer_epoch"]
        )
      )
    )
  end

  def parse_complete_event
    if recording = event.recording
      build_request_options(
        event.target_call_id,
        :type => :recording_completed,
        :params => compact_hash(
          :recording_duration => recording.duration.to_s,
          :recording_size => recording.size.to_s,
          :recording_uri => recording.uri
        )
      )
    end
  end

  def event
    options[:event]
  end

  private

  def compact_hash(hash)
    hash.delete_if { |k, v| v.nil? || v.empty? }
  end

  def build_request_options(phone_call_id, request_params)
    {
      :phone_call_id => phone_call_id,
      :params => request_params
    }
  end

  def default_request_params
    {
      :type => event_mapping[:type]
    }
  end

  def phone_call_id_from_headers
    event.headers["variable-uuid"]
  end

  def parse_event
    event_mapping[:event_parser] && event_mapping[:event_parser].call(self)
  end

  def phone_call_event_url(interpolations = {})
    event_url = configuration.rest_api_phone_call_events_url.dup
    interpolations.each do |interpolation, value|
      event_url.sub!(":#{interpolation}", value.to_s)
    end
    event_url
  end

  def event_mapping
    EVENT_MAPPINGS[event.class] || {}
  end
end
