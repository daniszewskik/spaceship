require 'spec_helper'

describe Spaceship::Client do
  class TestClient < Spaceship::Client

    def self.hostname
      "http://example.com"
    end

    def send_login_request(user, password)
      true
    end
  end

  let(:subject) { TestClient.new }
  let(:time_out_error) { Faraday::Error::TimeoutError.new }
  let(:unauth_error) { Spaceship::Client::UnauthorizedAccessError.new }
  let(:test_uri) { "http://example.com" }

  def send_request
    subject.send(:send_request, :get, test_uri, [], [])
  end

  def stub_client_request(error, times, status, body)
    stub_request(:get, test_uri).
      to_raise(error).times(times).then.
      to_return(status: status, body: body)
  end

  def stub_client_retry_auth(times, status_ok, status_ng, body)
    stub_request(:get, test_uri).to_return(status: status_ng, body: body).times(times).then.to_return(status: status_ok, body: body)
  end

  describe 'retry' do
    it "re-raises Timeout exception when retry limit reached" do
      stub_client_request(time_out_error, 6, 200, nil)

      expect do
        send_request
      end.to raise_error(time_out_error)
    end

    it "retries when AppleTimeoutError error raised" do
      body = '{foo: "bar"}'

      stub_client_request(time_out_error, 2, 200, body)

      expect(send_request.body).to eq(body)
    end

    it "raises AppleTimeoutError when response contains '302 Found'" do
      stub_connection_timeout_302

      expect do
        send_request
      end.to raise_error(Spaceship::Client::AppleTimeoutError)
    end

    it "retries login when UnauthorizedAccess Error raised" do
      body = '{foo: "bar"}'
      subject.login
      stub_client_retry_auth(1, 200, 401, body)
      expect(send_request.body).to eq(body)
    end

    it "re-raises Unauthorized Access exception if second login fails" do
      def subject.send_login_request(user, password)
        @data ||= Enumerator.new do |x|
          x.yield true
          x.yield (raise Spaceship::Client::UnauthorizedAccessError.new)
        end
        @data.next
      end

      body = '{foo: "bar"}'
      subject.login

      stub_client_retry_auth(1, 200, 401, body)
      expect do
        send_request
      end.to raise_error(Spaceship::Client::UnauthorizedAccessError)
    end
  end
end
