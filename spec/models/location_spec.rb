require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'associations' do
    it { should belong_to(:story) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:location)).to be_valid
    end
  end

  describe 'required fields' do
    it 'is invalid without a name' do
      location = build(:location, name: nil)
      expect(location).not_to be_valid
      expect(location.errors[:name]).to include("can't be blank")
    end

    it 'is valid without a description' do
      location = build(:location, description: nil)
      expect(location).to be_valid
    end

    it 'is invalid without a story' do
      location = build(:location, story: nil)
      expect(location).not_to be_valid
      expect(location.errors[:story]).to include("must exist")
    end
  end

  describe 'story association' do
    let(:story) { create(:story) }
    let(:location) { create(:location, story: story) }

    it 'belongs to a story' do
      expect(location.story).to eq(story)
    end

    it 'can access story attributes' do
      expect(location.story.title).to eq(story.title)
    end

    it 'can access story user through association' do
      expect(location.story.user).to eq(story.user)
    end
  end

  describe 'multiple locations per story' do
    let(:story) { create(:story) }
    let!(:castle) { create(:location, story: story, name: 'Dark Castle') }
    let!(:forest) { create(:location, story: story, name: 'Enchanted Forest') }
    let!(:village) { create(:location, story: story, name: 'Small Village') }

    it 'allows a story to have multiple locations' do
      expect(story.locations.count).to eq(3)
      expect(story.locations).to include(castle, forest, village)
    end

    it 'maintains different names for locations in same story' do
      names = story.locations.pluck(:name)
      expect(names).to contain_exactly('Dark Castle', 'Enchanted Forest', 'Small Village')
    end

    it 'allows duplicate location names across different stories' do
      another_story = create(:story)
      another_castle = create(:location, story: another_story, name: 'Dark Castle')
      expect(another_castle).to be_valid
    end
  end

  describe 'data integrity' do
    let(:location) { create(:location) }

    it 'saves name correctly' do
      location.update(name: 'New Location Name')
      expect(location.reload.name).to eq('New Location Name')
    end

    it 'saves description correctly' do
      location.update(description: 'A beautiful place with stunning views')
      expect(location.reload.description).to eq('A beautiful place with stunning views')
    end

    it 'handles long descriptions' do
      long_description = 'The location features ' * 50
      location.update(description: long_description)
      expect(location.reload.description).to eq(long_description)
    end
  end

  describe 'deletion behavior' do
    let(:story) { create(:story) }
    let!(:location) { create(:location, story: story) }

    it 'can be deleted independently without affecting story' do
      expect { location.destroy }.to change(Location, :count).by(-1)
      expect(Story.exists?(story.id)).to be true
    end

    it 'is deleted when parent story is deleted' do
      expect { story.destroy }.to change(Location, :count).by(-1)
    end
  end

  describe 'location types and descriptions' do
    let(:story) { create(:story) }

    it 'can create a location with minimal information' do
      location = create(:location, story: story, name: 'City', description: nil)
      expect(location).to be_persisted
    end

    it 'can create a location with detailed description' do
      description = "A sprawling metropolis with towering skyscrapers, bustling streets, and hidden alleyways that hold countless secrets."
      location = create(:location, 
                       story: story, 
                       name: 'Metropolitan City',
                       description: description)
      expect(location.description).to eq(description)
    end

    it 'can represent various types of locations' do
      indoor = create(:location, story: story, name: 'Library', 
                     description: 'A quiet indoor space filled with books')
      outdoor = create(:location, story: story, name: 'Mountain Peak', 
                      description: 'An outdoor location with panoramic views')
      fictional = create(:location, story: story, name: 'Dream Realm', 
                        description: 'A fictional place that exists only in imagination')
      
      expect([indoor, outdoor, fictional]).to all(be_persisted)
    end
  end
end