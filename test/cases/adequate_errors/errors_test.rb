require "minitest/autorun"
require "active_model"
require "models/topic"
require 'adequate_errors'

describe AdequateErrors::Errors do
  let(:model) { Topic.new }
  let(:rails_errors) { ActiveModel::Errors.new(model) }
  subject { AdequateErrors::Errors.new(model) }

  describe '#add' do
    it 'assigns attributes' do
      assert_equal 0, subject.size

      subject.add(:title, :not_attractive)

      assert_equal 1, subject.size
      assert_equal :title, subject.first.attribute
      assert_equal :not_attractive, subject.first.type
    end

    describe 'Proc provided' do
      it 'is moved to options' do
        proc = Proc.new { 'foo %{bar}' }
        subject.add(:title, proc, bar: 'bar')
        error = subject.first
        assert_equal :title, error.attribute
        assert_equal :invalid, error.type
        assert_equal proc, error.options[:message]
        assert_equal 'foo bar', error.message
      end
    end

    describe 'String provided' do
      it 'moves it to options' do
        text = 'too outdated'
        subject.add(:title, text)
        error = subject.first
        assert_equal :title, error.attribute
        assert_equal :invalid, error.type
        assert_equal text, error.options[:message]
      end
    end
  end

  describe '#import' do
    let(:inner_error) { AdequateErrors::Error.new(model, :foo, :not_attractive) }

    it 'creates a NestedError' do
      assert_equal 0, subject.size

      subject.import(inner_error)

      assert_equal 1, subject.size
      error = subject.first
      assert_equal :foo, error.attribute
      assert_equal :not_attractive, error.type
      assert_equal AdequateErrors::NestedError, error.class
      assert_equal inner_error, error.inner_error
    end
  end

  describe '#delete' do
    it 'assigns attributes' do
      subject.add(:title, :not_attractive)
      subject.add(:title, :not_provocative)
      subject.add(:content, :too_vague)

      subject.delete(:title)

      assert_equal 1, subject.size
    end
  end

  describe '#clear' do
    it 'assigns attributes' do
      subject.add(:title, :not_attractive)
      subject.add(:content, :too_vague)

      subject.clear

      assert_equal 0, subject.size
    end
  end

  describe '#blank?' do
    it 'returns true when empty' do
      assert_equal true, subject.blank?
    end

    it 'returns false when error is present' do
      subject.add(:title, :not_attractive)
      assert_equal false, subject.blank?
    end
  end

  describe '#empty?' do
    it 'returns true when empty' do
      assert_equal true, subject.empty?
    end

    it 'returns false when error is present' do
      subject.add(:title, :not_attractive)
      assert_equal false, subject.empty?
    end
  end

  describe '#where' do
    describe 'attribute' do
      it '' do
        subject.add(:title, :not_attractive)
        subject.add(:content, :too_vague)

        assert_equal 0,subject.where(:attribute => :foo).size
        assert_equal 1,subject.where(:attribute => :title).size
        assert_equal 1,subject.where(:attribute => :title, :type => :not_attractive).size
        assert_equal 0,subject.where(:attribute => :title, :type => :too_vague).size
        assert_equal 1,subject.where(:type => :too_vague).size
      end
    end
  end

  describe '#messages' do
    it 'returns an array of messages' do
      subject.add(:title, :invalid)
      subject.add(:content, :too_short, count: 5)

      assert_equal ["Title is invalid", "Content is too short (minimum is 5 characters)"], subject.messages
    end

    it 'returns empty array if no error exists' do
      assert_equal [], subject.messages
    end
  end

  describe '#messages_for' do
    it 'returns message of the match' do
      subject.add(:content, :too_short, count: 5)

      assert_equal 0, subject.messages_for(:attribute => :title).size
      assert_equal 1, subject.messages_for(:attribute => :content).size
      assert_equal 1, subject.messages_for(:attribute => :content, count: 5).size
      assert_equal 0, subject.messages_for(:attribute => :content, count: 0).size
    end
  end

  describe '#include?' do
    it 'returns true if attribute has error' do
      subject.add(:title, :invalid)
      assert subject.include?(:title)
    end

    it 'returns false if attribute has no error' do
      subject.add(:title, :invalid)
      assert !subject.include?(:content)
    end
  end

  describe '#to_hash' do
    it 'returns hash containing messages' do
      subject.add(:title, :invalid)
      subject.add(:content, :too_short, count: 5)

      assert_equal({title: ['Title is invalid'], content: ["Content is too short (minimum is 5 characters)"]}, subject.to_hash)
    end

    it 'returns empty hash' do
      assert_equal({}, subject.to_hash)
    end
  end
end