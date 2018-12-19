@App ||= {}

class @App
  constructor: ->
    @animation = new App.Animation()

  start: =>
    @animation.setup()

document.addEventListener 'DOMContentLoaded', ->
  app = new App()
  app.start()
