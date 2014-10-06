require 'httparty'

module Glosbe
  class Client
    include HTTParty
    format :json
    base_uri 'glosbe.com'
    #debug_output $stderr

    def query(word, from_lang, to_lang)
      options = {
          query: {
            from: from_lang,
            dest: to_lang,
            format: :json,
            phrase: word
          }
      }
      self.class.get('/gapi/translate', options)
    end

    def language_name(name)
      if name.eql? 'es'
        return 'spa'
      elsif name.eql? 'en'
        return 'eng'
      else
        return nil
      end
    end
  end
end