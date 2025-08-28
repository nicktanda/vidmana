require 'rails_helper'

RSpec.describe Beat, type: :model do
  describe 'associations' do
    it { should belong_to(:story) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:beat)).to be_valid
    end
  end

  describe 'required fields' do
    it 'is invalid without a title' do
      beat = build(:beat, title: nil)
      expect(beat).not_to be_valid
      expect(beat.errors[:title]).to include("can't be blank")
    end

    it 'is invalid without a description' do
      beat = build(:beat, description: nil)
      expect(beat).not_to be_valid
      expect(beat.errors[:description]).to include("can't be blank")
    end

    it 'is invalid without a story' do
      beat = build(:beat, story: nil)
      expect(beat).not_to be_valid
      expect(beat.errors[:story]).to include("must exist")
    end
  end

  describe 'story association' do
    let(:story) { create(:story) }
    let(:beat) { create(:beat, story: story) }

    it 'belongs to a story' do
      expect(beat.story).to eq(story)
    end

    it 'can access story attributes' do
      expect(beat.story.title).to eq(story.title)
    end

    it 'can access story user through association' do
      expect(beat.story.user).to eq(story.user)
    end
  end

  describe 'multiple beats per story' do
    let(:story) { create(:story) }
    let!(:beat1) { create(:beat, story: story, title: 'Opening Scene') }
    let!(:beat2) { create(:beat, story: story, title: 'Climax') }
    let!(:beat3) { create(:beat, story: story, title: 'Resolution') }

    it 'allows a story to have multiple beats' do
      expect(story.beats.count).to eq(3)
      expect(story.beats).to include(beat1, beat2, beat3)
    end

    it 'maintains different titles for beats in same story' do
      titles = story.beats.pluck(:title)
      expect(titles).to contain_exactly('Opening Scene', 'Climax', 'Resolution')
    end
  end

  describe 'data integrity' do
    let(:beat) { create(:beat) }

    it 'saves title correctly' do
      beat.update(title: 'New Beat Title')
      expect(beat.reload.title).to eq('New Beat Title')
    end

    it 'saves description correctly' do
      beat.update(description: 'A detailed description of this beat')
      expect(beat.reload.description).to eq('A detailed description of this beat')
    end

    it 'handles long descriptions' do
      long_description = 'Lorem ipsum ' * 100
      beat.update(description: long_description)
      expect(beat.reload.description).to eq(long_description)
    end
  end

  describe 'deletion behavior' do
    let(:story) { create(:story) }
    let!(:beat) { create(:beat, story: story) }

    it 'can be deleted independently without affecting story' do
      expect { beat.destroy }.to change(Beat, :count).by(-1)
      expect(Story.exists?(story.id)).to be true
    end

    it 'is deleted when parent story is deleted' do
      expect { story.destroy }.to change(Beat, :count).by(-1)
    end
  end
end