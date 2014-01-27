# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class raw extends BasePlugin
		# Plugin name
		name: 'raw'

		# Configuration
		config:
			# By default, copy the raw folder to the out directory.
			default:
				src: 'raw'

		# Writing all files has finished
		writeAfter: (opts,next) ->
			# Import
			ncp = require('ncp')
			safeps = require('safeps')
			pathUtil = require('path')

			# Prepare
			docpad = @docpad
			docpadConfig = @docpad.getConfig()

			# Set out directory
			# the trailing / indicates to cp that the files of this directory should be copied over
			# rather than the directory itself
			outPath = pathUtil.normalize(docpadConfig.outPath)
			srcPath = pathUtil.normalize(docpadConfig.srcPath)
			# @TODO: why do we need to normalize these?

			process = (target, key) ->
				docpad.log("info", "Copying #{key}")

				# Use command if specified instead of ncp
				if target.command
					WINDOWS = /win/.test(process.platform)
					CYGWIN = /cygwin/.test(process.env.PATH)  # Cheap test!
					XCOPY = WINDOWS && !CYGWIN

					target.command or= (
						if XCOPY
							['xcopy', '/e', 'src\\raw\\*', 'out\\']
						else
							['cp', '-Rn', 'src/raw/*', 'out/' ]
					)

					command = target.command.map (part) ->
						part.replace(/^out/, outPath).replace(/^src/, srcPath)

					safeps.spawn command, {output:false}, (err) ->
						return next(err) if err
						docpad.log('debug', "Copied raw directory")
						return next()

				# Otherwise use ncp by default
				else
					src = pathUtil.join(srcPath, target.src)

					# Use ncp settings if specified
					options = if target.options? and typeof target.options is 'object' then target.options else {}

					docpad.log('debug', "raw plugin info... out: #{outPath}, src: #{src}, options: #{JSON.stringify(options)}")

					ncp src, outPath, options, (err) ->
						return next(err) if err
						docpad.log('debug', "Done copying #{key}")
						return next()

			process(target, key) for target, key of @getConfig()

