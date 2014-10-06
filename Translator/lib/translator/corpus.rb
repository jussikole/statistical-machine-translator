require 'tokenizer'
require 'zlib'

module Corpus
  class Corpus
    def initialize(lang1, lang2, lang, lite=false)
      @lang1 = lang1
      @lang2 = lang2
      @lang = lang
      @tokenizer = Tokenizer::Tokenizer.new
      @lite = lite
    end

    def filepath
      add = @lite? '-lite' : ''
      "resources/corpus/europarl-v7.#{@lang1}-#{@lang2}#{add}.#{@lang}"
    end

    def iterate
      File.open(filepath, 'r') do |file|
        while (line = file.gets)
          yield parse(line)
        end
      end
    end

    def lang
      @lang
    end

    def read(batch_size)
      buffer = []
      puts "Reading corpus from #{filepath}"
      File.open(filepath, 'r') do |f|
        line_counter = 0
        f.each_line do |line|
          buffer << parse(line)
          line_counter += 1

          if line_counter == batch_size
            yield buffer
            buffer.clear
            line_counter = 0
          end
        end
      end
    end

    def read_to_queue(queue)
      File.open(filepath, 'r') do |f|
        f.each_line do |line|
          queue << parse(line)
        end
      end
    end


    def parse(line)
      @tokenizer.tokenize(line).find_all { |word| word.downcase if word? word }
    end

    def word?(word)
      word =~ /\A[a-z]+\z/ and word.length > 0
    end

    def stopwords(lang)
      s = {
          en: ['a', 'of', 'to', 'from', 'until', 'till', 'an', 'the', ''],
          es: []
      }
      s[lang]
    end
  end
end