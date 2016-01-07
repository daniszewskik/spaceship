require 'spec_helper'
describe Spaceship::Client do
  class TestClient < Spaceship::Client
    def self.hostname
      "https://www.howsmyssl.com"
    end
  end
  let(:client) { TestClient.new }
  before { WebMock.allow_net_connect! }
  after { WebMock.disable_net_connect! }

  it 'doesn\'t use weak ciphers when secured' do
    json = client.send('request', :get, 'a/check').body
    # Bad ?
    expect(json['insecure_cipher_suites']).to eq({})
    # improvable ?
    expect(json['tls_version']).to eq('TLS 1.2')
    expect(json['ephemeral_keys_supported']).to eq(true)
    expect(json['session_ticket_supported']).to eq(true)
    # Probably Okay
    expect(json['rating']).to eq('Probably Okay')
  end
end
