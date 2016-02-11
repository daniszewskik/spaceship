require 'spec_helper'

describe Spaceship::Client do
  class TestClient < Spaceship::Client
    def self.hostname
      "http://example.com"
    end
  end

  let(:subject) { TestClient.new }
  let(:time_out_error) { Faraday::Error::TimeoutError.new }
  let(:test_uri) { "http://example.com" }

  def send_request
    subject.send(:send_request, :get, test_uri, [], [])
  end

  def stub_client_request(error, times, status, body)
    stub_request(:get, test_uri).
      to_raise(error).times(times).then.
      to_return(status: status, body: body)
  end

  describe 'retry' do
    it "can retry" do
      stub_client_request(time_out_error, 6, 200, nil)

      expect do
        send_request
      end.to raise_error(time_out_error)
    end

    it "can recover retries" do
      body = '{foo: "bar"}'

      stub_client_request(time_out_error, 2, 200, body)

      expect(send_request.body).to eq(body)
    end
  end
end
