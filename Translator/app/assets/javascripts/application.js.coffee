# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require_tree .

$ ->
  $('button#send').click ->
    $('#search').addClass('up')
    query = $('input#query').val()
    lambda = $('input#lambda').val()
    from_lang = $('select#lang1').val()
    to_lang = $('select#lang2').val()

    #alert("#{query} #{lambda} #{from_lang} #{to_lang}")
    results = $('#results')
    results.html('<img src="assets/spinner1.gif">')


    $.getJSON('/translate', {sentence: query, lambda: lambda, from_lang: from_lang, to_lang: to_lang}, (data) ->
      results.html('')
      if data.error
        results.html(data.error)
      else
        for word in data
          row = $('<div class="list"></div>')
          row.append("<div class='title'>#{word.word}</div>")

          translations = $('<div class="translations"></div>')
          i = 0
          for possibility in word.translations
            if i++ == 0
              translations.append("<div class='best-translation'>#{possibility[0]}: #{possibility[1]}</div>")
            else
              translations.append("<div class='translation'>#{possibility[0]}: #{possibility[1]}</div>")
            i++
          row.append(translations)
          results.append(row)
    )


