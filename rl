#!/usr/bin/env coffee

request = require 'request'

options =
	uri: 'http://www.ripline.io/graphql',
	method: 'POST',
	json:
		query: """
			query snippets($text: String!) {
				snippets(text: $text) {
					_id
					title
					text
					username
				}
			}
		"""
		variables: text: process.argv[2..].join ' '

request options, (error, response, body) ->
	if not error? and response.statusCode is 200
		if body?.data?.snippets?[0]?.text?
			process.stdout.write body.data.snippets[0].text
			process.stdout.write '\n'
	else
		console.log "Message: ", body.text
		console.log "Error: ", error
		console.log "Status code was: ", response.statusCode
