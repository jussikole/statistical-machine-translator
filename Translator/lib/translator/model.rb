require_relative 'index'
require_relative 'timer'

module Model
  class LanguageModel
    def initialize(lang, index, lambda)
      @index = index
      @lambda = lambda
      @lang = lang
    end

    def bigram_probability(word1, word2)
      Timer.start "calculating bigram probability for '#{word1}' and '#{word2}'"
      freq1 = @index.term_frequency(@lang, word1) + 2
      a = (1.0 * freq1) / @index.n_terms(@lang) rescue 0
      b = (1.0 * @index.bigram_frequency(@lang, word1, word2)) / freq1 rescue 0
      Timer.stop
      @lambda * a + (1 - @lambda) * b
    end
  end

  class TranslationModel
    def initialize(lang1, lang2, index, lambda)
      @lang1 = lang1
      @lang2 = lang2
      @index = index
      @lambda = lambda
    end

    def occurrence_probability(word1, word2)
      Timer.start "calculating translation probability for '#{word1}' and '#{word2}'"
      freq2 = @index.term_frequency(@lang2, word2)
      a = (1.0 * freq2) / @index.corpus_size rescue 0
      b = (1.0 * @index.occurrence_frequency(@lang1, word1, @lang2, word2)) / freq2 rescue 0
      Timer.stop
      @lambda * a + (1 - @lambda) * b
    end
  end

  class Optimizer
    def initialize(lang1, lang2, lambda, index)
      @lang1 = lang1
      @lang2 = lang2
      @lambda = lambda
      @language_model = LanguageModel.new(lang2, index, lambda)
    end

    def execute(sentence)
      max_index = [0]*sentence.length
      probabilities = sentence.map { |s| [0]*s.length }

      max_probability = 0
      sentence[0].length.times do |i|
        sentence[1].length.times do |j|
          probability = @language_model.bigram_probability sentence[0][i], sentence[1][j]
          probabilities[0][i] = probability
          probabilities[1][j] = probability
          if probability > max_probability
            max_probability = probability
            max_index[0,2] = [i, j]
          end
        end
      end


      sentence.length.times do |i|
        next if i < 2
        max_probability = 0
        max_index = 0
        sentence[i].length.times do |j|
          probability = @language_model.bigram_probability sentence[i-1][max_index[i-1]], sentence[i][j]
          probabilities[i][j] = probability
          if probability > max_probability
            max_probability = probability
            max_index[i] = j
          end
        end
      end


    end


  end

end