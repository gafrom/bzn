class @App.Animation

  setup: =>
    @assignDelays '.slidable'
    @assignFocus '.slidable.first'

  assignFocus: (query) ->
    firstField = document.querySelector(query)
    events = ['animationstart', 'webkitAnimationStart', 'mozanimationstart', 'MSAnimationStart', 'oanimationstart']
    for event in events
      firstField.addEventListener event, ->
        setTimeout (-> document.querySelector("#{query}>input").focus()), 2500

  assignDelays: (query) ->
    elems = document.querySelectorAll query

    delay = 0.0
    for elem in elems
      elem.style.animationDelay = "#{delay += 0.05}s"
