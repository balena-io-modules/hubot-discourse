AbstractAPIAdapter = require 'hubot-abstract-api-adapter'
try
	{ TextMessage } = require 'hubot'
catch
	prequire = require 'parent-require'
	{ TextMessage } = prequire 'hubot'

class Discourse extends AbstractAPIAdapter
	constructor: ->
		try
			super
		catch error
			if error not instanceof TypeError
				throw error

	poll: =>
		@getUntil(
			{
				url: process.env.HUBOT_DISCOURSE_API_URL + '/posts.json'
				headers: { Accept: 'application/json' }
				qs: {
					api_key: process.env.HUBOT_DISCOURSE_API_TOKEN
					api_username: process.env.HUBOT_DISCOURSE_API_USERNAME
				}
			}
			@processMessage
			(obj) => obj.id > ( @robot.brain.get('AdapterDiscourseLastKnown') ? -1 )
			(err, res) =>	if not err then @robot.brain.set('AdapterDiscourseLastKnown', res[0].id)
		)

	processMessage: (message) =>
		author = @robot.brain.userForId(
			message.username
			{ name: message.display_username, room: message.category_id }
		)
		message = new TextMessage(
			author
			@robot.name + ': ' + message.raw
			message.id
			{ ids: { comment: message.id, thread: message.topic_id, flow: message.category_id } }
		)
		@robot.receive(message)

	extractResults: (obj) ->
		obj?.latest_posts

	extractNext: ->
		null

exports.use = (robot) ->
	new Discourse robot
