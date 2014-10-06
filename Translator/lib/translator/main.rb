require 'rubygems'
require 'lingua/stemmer'

require_relative 'corpus'
require_relative 'timer'
require_relative 'index'

lang1 = 'es'
lang2 = 'en'
lambda = 0




corpus_es = Corpus::Corpus.new(lang1, lang2, lang1, false)
corpus_en = Corpus::Corpus.new(lang1, lang2, lang2, false)

index = Index::TranslationIndex.new

Timer.start 'reading corpuses'
index.create 1572587, 1000, corpus_es, corpus_en
Timer.stop

