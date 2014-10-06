require 'tokenizer'

class JsonController < ApplicationController
  respond_to :json

  def available_languages
    %(es en)
  end

  def translate
    lang1 = params[:from_lang]
    lang2 = params[:to_lang]
    if lang1.nil? or lang2.nil? or !available_languages.include? lang1 or !available_languages.include? lang2 or lang1.eql? lang2
      render json: {error: 'Invalid languages'} and return
    end

    lambda = params[:lambda].to_f || 0

    tokenizer = Tokenizer::Tokenizer.new
    sentence = tokenizer.tokenize params[:sentence]



    dictionary = Dictionary::OnlineDictionary.new(lang1, lang2)
    translation = dictionary.translate_sentence sentence
    puts translation.inspect

    index = Index::TranslationIndex.new

    optimizer = Model::Optimizer.new lang1, lang2, lambda, index
    max_index, probabilities = optimizer.iterate(3, translation)

    result = []
    translation.size.times do |i|
      puts translation[i].size
      r = { word: sentence[i], translations: [] }
      translation[i].size.times do |j|
        r[:translations] << [translation[i][j], probabilities[i][j]]
      end
      result << r
    end



    render json: result
  end
end
