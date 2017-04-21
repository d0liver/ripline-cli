#!/usr/bin/env coffee
fs       = require 'fs'
crypto   = require 'crypto'
{exec}   = require 'child_process'
request  = require 'request'
minimist = require 'minimist'

getSnip = (tags, cb) ->

	options =
		uri: uri
		method: 'POST'
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
			variables: text: tags.join ' '

	request options, (error, response, body) ->
		if not error? and response.statusCode is 200 and text = body?.data?.snippets?[0]?.text
			cb null, text
		else if error or response.statusCode isnt 200
			process.stderr.write "Request error: #{response.statusCode}\n"
			process.stderr.write "Body: \n #{body.text}\n"
		# Otherwise we just didn't get a matching snippet back so we do nothing.

doCommand = (command, args) ->
	switch command
		when 'fetch'
			getSnip args, (error, text) ->
				newline = if argv.n then '' else '\n'
				process.stdout.write "#{text}#{newline}"
		when 'edit'
			getSnip args, (error, text) ->
				getModifiedSnippet text, (text) ->
					process.stdout.write text
		when 'list-tags'
			getTags (error, tags) ->
				process.stdout.write "#{tag}\n" for tag in tags

		when 'update'
			process.stderr.write "Updating tags...\n"
			dest_dir =
				if args.length isnt 0
					args[0]
				else
					"#{process.env.HOME}/.cache/ripline"

			updateTags dest_dir, (error, result) ->
				process.stderr.write "Finished\n"

touch = (fname) ->
	fs.closeSync fs.openSync fname, 'w'

generateNonce = ->
	buf = crypto.randomBytes 8
	return buf.toString('base64').replace(/\//g,'_').replace(/\+/g,'-')

getTags = (cb) ->
	request
		uri: uri
		method: 'POST'
		json:
			query: """
				{
					tags
				}
			"""
		, (error, response, body) ->
			cb null, body.data.tags

updateTags = (dest_dir, cb) ->
	console.log "Dest dir: ", dest_dir
	# Strip off the trailing slash if there is one
	dest_dir = dest_dir.slice(0, -1) if dest_dir.charAt(dest_dir.length - 1) is '/'

	getTags (error, tags) ->
		# Put the lower cased variants in the file as well for easier use (I
		# pretty much always type the lower cased tag names)
		for tag in tags when /[A-Z]/.test tag
			tags.push tag.toLowerCase()

		fs.mkdirSync dest_dir unless fs.existsSync dest_dir
		fs.writeFileSync "#{dest_dir}/tags", tags.join '\n'
		cb null, null

getModifiedSnippet = (snip_text, cb) ->

	fname = "/tmp/#{generateNonce()}"
	# process.stderr.write "Creating tmp file: #{fname}\n"

	fs.writeFileSync fname, snip_text

	# process.stderr.write "Opening tmp file in editor...\n"

	# -n indicates that the text should be placed in the file without being
	# expanded as a snippet. Otherwise we delete the file contents (snippet) to
	# the clipboard and then expand the snippet from the clipboard.
	vim_commands = [
		# Initial window resize s out temporarily because there are problems
		# with it right now (doesn't snap to full screen like it should and
		# problems in pipes).
		# "set lines=#{process.stdout.rows}"
		# "set columns=#{process.stdout.columns}"
	]

	unless argv.n
		vim_commands.push [
			"normal gg\"+dG"
			"call RiplinePaste()"
		]...

	vim_commands = vim_commands.reduce (str, command) ->
		"#{str} +'#{command}'"
	, ''

	exec "#{process.env.EDITOR} #{vim_commands} #{fname}", (error, stdout, stderr) ->
		if error
			process.stderr.write "Error: #{error}"
			return
		contents = fs.readFileSync fname, 'utf8'
		# Clean up the temp file
		fs.unlinkSync fname
		cb contents

minimist_opts =
	boolean: ['dev', 'n']
	default:
		dev: false

argv = minimist process.argv.slice(2), minimist_opts
[command, command_args...] = argv._

uri = if argv.dev
		'http://localhost:3000/graphql'
	else
		'http://www.ripline.io/graphql'

doCommand command, command_args
