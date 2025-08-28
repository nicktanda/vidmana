require 'rails_helper'

RSpec.describe Story, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:beats).dependent(:destroy) }
    it { should have_many(:characters).dependent(:destroy) }
    it { should have_many(:locations).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:story)).to be_valid
    end
  end

  describe 'required fields' do
    it 'is invalid without a title' do
      story = build(:story, title: nil)
      expect(story).not_to be_valid
      expect(story.errors[:title]).to include("can't be blank")
    end

    it 'is invalid without a user' do
      story = build(:story, user: nil)
      expect(story).not_to be_valid
      expect(story.errors[:user]).to include("must exist")
    end

    it 'is valid without a description' do
      story = build(:story, description: nil)
      expect(story).to be_valid
    end
  end

  describe 'cascading deletes' do
    let(:story) { create(:story) }
    let!(:beat) { create(:beat, story: story) }
    let!(:character) { create(:character, story: story) }
    let!(:location) { create(:location, story: story) }

    it 'destroys associated beats when story is destroyed' do
      expect { story.destroy }.to change(Beat, :count).by(-1)
    end

    it 'destroys associated characters when story is destroyed' do
      story_with_character = create(:story)
      character = create(:character, story: story_with_character)
      expect { story_with_character.destroy }.to change(Character, :count).by(-1)
    end

    it 'destroys associated locations when story is destroyed' do
      story_with_location = create(:story)
      location = create(:location, story: story_with_location)
      expect { story_with_location.destroy }.to change(Location, :count).by(-1)
    end

    it 'destroys all associated records when story is destroyed' do
      initial_beats = Beat.count
      initial_characters = Character.count
      initial_locations = Location.count
      
      story.destroy
      
      expect(Beat.count).to eq(initial_beats - 1)
      expect(Character.count).to eq(initial_characters - 1)
      expect(Location.count).to eq(initial_locations - 1)
    end
  end

  describe 'user association' do
    let(:user) { create(:user) }
    let(:story) { create(:story, user: user) }

    it 'belongs to a user' do
      expect(story.user).to eq(user)
    end

    it 'can access user attributes' do
      expect(story.user.name).to eq(user.name)
      expect(story.user.email).to eq(user.email)
    end
  end

  describe 'multiple stories per user' do
    let(:user) { create(:user) }
    let!(:story1) { create(:story, user: user) }
    let!(:story2) { create(:story, user: user) }

    it 'allows a user to have multiple stories' do
      expect(user.stories.count).to eq(2)
      expect(user.stories).to include(story1, story2)
    end
  end
end