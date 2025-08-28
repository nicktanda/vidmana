require 'rails_helper'

RSpec.describe Character, type: :model do
  describe 'associations' do
    it { should belong_to(:story) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:character)).to be_valid
    end
  end

  describe 'required fields' do
    it 'is invalid without a name' do
      character = build(:character, name: nil)
      expect(character).not_to be_valid
      expect(character.errors[:name]).to include("can't be blank")
    end

    it 'is valid without a description' do
      character = build(:character, description: nil)
      expect(character).to be_valid
    end

    it 'is invalid without a story' do
      character = build(:character, story: nil)
      expect(character).not_to be_valid
      expect(character.errors[:story]).to include("must exist")
    end
  end

  describe 'story association' do
    let(:story) { create(:story) }
    let(:character) { create(:character, story: story) }

    it 'belongs to a story' do
      expect(character.story).to eq(story)
    end

    it 'can access story attributes' do
      expect(character.story.title).to eq(story.title)
    end

    it 'can access story user through association' do
      expect(character.story.user).to eq(story.user)
    end
  end

  describe 'multiple characters per story' do
    let(:story) { create(:story) }
    let!(:protagonist) { create(:character, story: story, name: 'Hero') }
    let!(:antagonist) { create(:character, story: story, name: 'Villain') }
    let!(:sidekick) { create(:character, story: story, name: 'Sidekick') }

    it 'allows a story to have multiple characters' do
      expect(story.characters.count).to eq(3)
      expect(story.characters).to include(protagonist, antagonist, sidekick)
    end

    it 'maintains different names for characters in same story' do
      names = story.characters.pluck(:name)
      expect(names).to contain_exactly('Hero', 'Villain', 'Sidekick')
    end

    it 'allows duplicate names across different stories' do
      another_story = create(:story)
      another_hero = create(:character, story: another_story, name: 'Hero')
      expect(another_hero).to be_valid
    end
  end

  describe 'data integrity' do
    let(:character) { create(:character) }

    it 'saves name correctly' do
      character.update(name: 'New Character Name')
      expect(character.reload.name).to eq('New Character Name')
    end

    it 'saves description correctly' do
      character.update(description: 'A mysterious figure with a dark past')
      expect(character.reload.description).to eq('A mysterious figure with a dark past')
    end

    it 'handles long descriptions' do
      long_description = 'Background story ' * 50
      character.update(description: long_description)
      expect(character.reload.description).to eq(long_description)
    end
  end

  describe 'deletion behavior' do
    let(:story) { create(:story) }
    let!(:character) { create(:character, story: story) }

    it 'can be deleted independently without affecting story' do
      expect { character.destroy }.to change(Character, :count).by(-1)
      expect(Story.exists?(story.id)).to be true
    end

    it 'is deleted when parent story is deleted' do
      expect { story.destroy }.to change(Character, :count).by(-1)
    end
  end

  describe 'character types and descriptions' do
    let(:story) { create(:story) }

    it 'can create a character with minimal information' do
      character = create(:character, story: story, name: 'John', description: nil)
      expect(character).to be_persisted
    end

    it 'can create a character with detailed description' do
      description = "A complex character with multiple layers of personality, including strengths, weaknesses, and a compelling backstory."
      character = create(:character, 
                        story: story, 
                        name: 'Jane Doe',
                        description: description)
      expect(character.description).to eq(description)
    end
  end
end