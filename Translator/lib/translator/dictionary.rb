require_relative 'glosbe'

module Dictionary
  LONGEST_PHRASE = 2

  class OnlineDictionary
    def initialize(lang1, lang2, api=Glosbe::Client.new)
      @lang1 = api.language_name lang1
      @lang2 = api.language_name lang2
      @api = api
    end

    def translate(word, lang)
      from_lang = (lang.eql? @lang1) ? @lang1 : @lang2
      to_lang = (lang.eql? @lang1) ? @lang2 : @lang1

      puts "Translating #{word} from #{from_lang} to #{to_lang}"
      return nil if from_lang.nil? or to_lang.nil?

      results = []
      response = @api.query(word, from_lang, to_lang)
      response['tuc'].each do |tuc|
        phrase = tuc['phrase']
        next if phrase.nil?
        next unless phrase['language'].eql? to_lang and word_translation?(phrase['text'])
        results << phrase['text']
      end
      results
    end

    def translate_sentence(sentence)
      translations = {}
      threads = []
      sentence.size.times do |i|
        threads << Thread.new {
          translations[i] = translate(sentence[i], @lang1)
          puts translations.inspect
        }
      end
      threads.map { |thread| thread.join }
      result = []
      translations.size.times do |j|
        result << translations[j]
      end
      result
    end

    def word_translation?(phrase)
      phrase.split.count <= LONGEST_PHRASE and /\A[a-z\s]+\z/.match(phrase)
    end
  end

  class OfflineDictionary
    def initialize

    end

    def translate(word, lang)

    end
  end
end