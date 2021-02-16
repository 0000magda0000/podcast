require 'rails_helper'

RSpec.describe Episode, type: :model do
  context "model test" do
    it 'ensure episode has title and permalink' do
      episode = Episode.new
      episode.title = "my title"
      episode.permalink = "http://mypl.com"
      episode.save!
      expect([episode.reload.title, episode.reload.permalink]).to eq([episode.title, episode.permalink])
    end
  end
end
