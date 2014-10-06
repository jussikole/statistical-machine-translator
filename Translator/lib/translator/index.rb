require_relative 'timer'
require 'redis'
require 'thread'
require 'rubygems'
require 'lingua/stemmer'

module Index
  class TranslationIndex
    def initialize(redis_keys=RedisKeysNew.new)
      @redis = Redis.new
      @redis_keys = redis_keys
      @work = false

      @queue1 = Queue.new
      @queue2 = Queue.new
    end

    def create_multithreaded(n_workers, corpus1, corpus2)
      puts 'flushing db'
      @redis.flushdb


      @work = true
      consumer_threads = []

      puts "starting #{@n_workers} consumers for #{corpus1.lang}"
      consumer_threads << @n_workers.times do |id|
        Thread.new{
          index_from_queue(id+1, corpus1.lang, @queue1)
        }
      end


      puts  "starting #{@n_workers} consumers for #{corpus2.lang}"
      consumer_threads << @n_workers.times do |id|
        Thread.new{
          index_from_queue(id+1, corpus2.lang, @queue2)
        }
      end

      producer_threads = []
      puts "starting producers for #{corpus1.lang} and #{corpus2.lang}\n"
      producer_threads << Thread.new { corpus1.read_to_queue(@queue1) }
      producer_threads << Thread.new { corpus2.read_to_queue(@queue2) }


      producer_threads.map { |t| t.join }
      puts 'producers stopped'
      @work = false

      consumer_threads.map { |t| t.join }
      puts 'consumers stopped'
    end

    def create(n_lines, batch_size, corpus1, corpus2)
      @stemmer = {
          corpus1.lang => Lingua::Stemmer.new(:language => corpus1.lang),
          corpus2.lang => Lingua::Stemmer.new(:language => corpus2.lang)
      }

      puts 'flushing db'
      @redis.flushdb

      threads = []
      #threads << Thread.new { index corpus1 }
      threads << Thread.new { index n_lines, batch_size, corpus2 }
      threads.map { |t| t.join }
    end

    def index_from_queue(id, lang, queue)
      puts "Worker #{lang}-#{id} started\n"
      n = 0
      while @work
        sentence = queue.pop
        sentence_index = @redis.incr @redis_keys.sentence_counter(lang)
        index_sentence lang, sentence_index, sentence
        n += 1
      end
      puts "Worker #{lang}-#{id} stopped after #{n} sentences"
    end

    def index(n_lines, batch_size, corpus)
      i = 0
      finished = false
      corpus.read(batch_size) do |lines|
        Timer.start "Reading batch of size #{batch_size}"
        @redis.pipelined do
          lines.each do |sentence|
            i += 1
            index_sentence corpus.lang, i, sentence
            if i == n_lines
              finished = true
              break
            end
          end
        end
        Timer.stop
        break if finished
      end
    end

    def index_sentence(lang, sentence_index, sentence)


      previous_term = nil
      sentence.each do |term|

        @redis.incr @redis_keys.word(lang, term)
        @redis.incr @redis_keys.bigram(lang, previous_term, term) if previous_term
        previous_term = term

        stem = @stemmer[lang].stem term
        @redis.rpush @redis_keys.stem(lang, stem), term unless stem.eql? term
        @redis.sadd @redis_keys.sentence(lang, sentence_index), term
        @redis.rpush @redis_keys.word_sentences(lang, term), sentence_index

      end

    end

    def term_frequency(lang, term)
      term_index = @redis.get @redis_keys.term_index(lang, term)
      @redis.llen @redis_keys.term_sentences lang, term_index
    end

    def bigram_frequency(lang, term1, term2)
      term_index1 = @redis.get @redis_keys.term_index(lang, term1)
      term_index2 = @redis.get @redis_keys.term_index(lang, term2)
      @redis.get @redis_keys.bigram_frequency lang, term_index1, term_index2
    end

    def occurrence_frequency(lang1, term1, lang2, term2)
      term_index1 = @redis.get @redis_keys.term_index(lang1, term1)
      term_index2 = @redis.get @redis_keys.term_index(lang2, term2)
      sentences1 = @redis.lrange @redis_keys.term_sentences(lang, term_index1), 0, -1
      sentences2 = @redis.lrange @redis_keys.term_sentences(lang, term_index2), 0, -1
      sentences1 & sentences2
    end

    def n_terms(lang)
      @redis.get @redis_keys.term_counter(lang)
    end

    def n_sentences(lang)
      @redis.get @redis_keys.sentence_counter(lang)
    end

  end

  class RedisKeys
    def term_counter(lang)
      "term:counter:#{lang}"
    end

    def term_index(lang, term)
      "term:#{lang}:#{term}"
    end

    def term(lang, index)
      "term:#{lang}:#{index}"
    end

    def bigram_frequency(lang, index1, index2)
      "bigram:#{lang}:#{index1}:#{index2}"
    end

    def sentence_counter(lang)
      "sentence:counter:#{lang}"
    end

    def sentence(lang, index)
      "sentence:#{lang}:#{index}"
    end

    def term_sentences(lang, index)
      "term:#{lang}:#{index}:sentences"
    end

  end

  class RedisKeysNew
    def stem(lang, stem)
      "#{lang}:stem:#{stem}"
    end

    def word(lang, word)
      "#{lang}:word:#{word}"
    end

    def word_freuqency(lang, word)
      "#{lang}:word:#{word}:frequency"
    end

    def word_sentences(lang, word)
      "#{lang}:word:#{word}:sentences"
    end

    def sentence_counter(lang)
      "#{lang}:sentence:counter"
    end

    def sentence(lang, index)
      "#{lang}:sentence:#{index}"
    end

    def bigram(lang, word1, word2)
      "#{lang}:bigram:#{word1}:#{word2}"
    end
  end
end