#!/usr/bin/env coffee
fs = require 'fs'
crypto = require 'crypto'
{exec} = require 'child_process'
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
		text = body?.data?.snippets?[0]?.text
		if text?
			getModifiedSnippet text, (text) ->
				process.stdout.write "#{text}"
	else
		process.stderr.write "Request error: #{response.statusCode}\n"
		process.stderr.write "Body: \n #{body.text}\n"


touch = (fname) ->
	fs.closeSync fs.openSync fname, 'w'

generateNonce = ->
	buf = crypto.randomBytes 8
	return buf.toString('base64').replace(/\//g,'_').replace(/\+/g,'-')

getModifiedSnippet = (snip_text, cb) ->

	fname = "/tmp/#{generateNonce()}"
	# process.stderr.write "Creating tmp file: #{fname}\n"

	fs.writeFileSync fname, snip_text

	# process.stderr.write "Opening tmp file in editor...\n"

	exec "#{process.env.EDITOR} +'normal gg\"+dG' +'call RiplinePaste()' #{fname}", (error, stdout, stderr) ->
		if error
			process.stderr.write "Error: #{error}"
			return
		contents = fs.readFileSync fname, 'utf8'
		# Clean up the temp file
		fs.unlinkSync fname
		cb contents
