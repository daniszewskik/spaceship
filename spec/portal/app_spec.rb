require 'spec_helper'

describe Spaceship::Portal::App do
  before { Spaceship.login }
  let(:client) { Spaceship::Portal::App.client }

  describe "successfully loads and parses all apps" do
    it "the number is correct" do
      expect(Spaceship::Portal::App.all.count).to eq(5)
    end

    it "inspect works" do
      expect(Spaceship::Portal::App.all.first.inspect).to include("Portal::App")
    end

    it "parses app correctly" do
      app = Spaceship::Portal::App.all.first

      expect(app.app_id).to eq("B7JBD8LHAA")
      expect(app.name).to eq("The App Name")
      expect(app.platform).to eq("ios")
      expect(app.prefix).to eq("5A997XSHK2")
      expect(app.bundle_id).to eq("net.sunapps.151")
      expect(app.is_wildcard).to eq(false)
    end

    it "parses wildcard apps correctly" do
      app = Spaceship::Portal::App.all.last

      expect(app.app_id).to eq("L42E9BTRAA")
      expect(app.name).to eq("SunApps")
      expect(app.platform).to eq("ios")
      expect(app.prefix).to eq("5A997XSHK2")
      expect(app.bundle_id).to eq("net.sunapps.*")
      expect(app.is_wildcard).to eq(true)
    end

    it "parses app details correctly" do
      app = Spaceship::Portal::App.all.first
      app = app.details

      expect(app.app_id).to eq("B7JBD8LHAA")
      expect(app.name).to eq("The App Name")
      expect(app.platform).to eq("ios")
      expect(app.prefix).to eq("5A997XSHK2")
      expect(app.bundle_id).to eq("net.sunapps.151")
      expect(app.is_wildcard).to eq(false)

      expect(app.features).to include("push" => true)
      expect(app.enabled_features).to include("push")
      expect(app.dev_push_enabled).to eq(false)
      expect(app.prod_push_enabled).to eq(true)
      expect(app.app_groups_count).to eq(0)
      expect(app.cloud_containers_count).to eq(0)
      expect(app.identifiers_count).to eq(0)
    end

    it "allows modification of values and properly retrieving them" do
      app = Spaceship::App.all.first
      app.name = "12"
      expect(app.name).to eq("12")
    end
  end


  describe "Filter app based on app identifier" do

    it "works with specific App IDs" do
      app = Spaceship::Portal::App.find("net.sunapps.151")
      expect(app.app_id).to eq("B7JBD8LHAA")
      expect(app.is_wildcard).to eq(false)
    end

    it "works with wilcard App IDs" do
      app = Spaceship::Portal::App.find("net.sunapps.*")
      expect(app.app_id).to eq("L42E9BTRAA")
      expect(app.is_wildcard).to eq(true)
    end

    it "returns nil app ID wasn't found" do
      expect(Spaceship::Portal::App.find("asdfasdf")).to be_nil
    end
  end

  describe '#create' do
    it 'creates an app id with an explicit bundle_id' do
      expect(client).to receive(:create_app!).with(:explicit, 'Production App', 'tools.fastlane.spaceship.some-explicit-app') {
        {'isWildCard' => true}
      }
      app = Spaceship::Portal::App.create!(bundle_id: 'tools.fastlane.spaceship.some-explicit-app', name: 'Production App')
      expect(app.is_wildcard).to eq(true)
    end

    it 'creates an app id with a wildcard bundle_id' do
      expect(client).to receive(:create_app!).with(:wildcard, 'Development App', 'tools.fastlane.spaceship.*') {
        {'isWildCard' => false}
      }
      app = Spaceship::Portal::App.create!(bundle_id: 'tools.fastlane.spaceship.*', name: 'Development App')
      expect(app.is_wildcard).to eq(false)
    end
  end

  describe '#delete' do
    subject { Spaceship::Portal::App.find("net.sunapps.151") }
    it 'deletes the app by a given bundle_id' do
      expect(client).to receive(:delete_app!).with('B7JBD8LHAA')
      app = subject.delete!
      expect(app.app_id).to eq('B7JBD8LHAA')
    end
  end
end
