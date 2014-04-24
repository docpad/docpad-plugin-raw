# Export Plugin
module.exports = (BasePlugin) ->
	# Define Plugin
	class raw extends BasePlugin
		# Plugin name
		name: 'raw'

		# Writing all files has finished
		writeAfter: (opts,next) ->
			# Import
			eachr = require('eachr')
			ncp = require('ncp')
			safeps = require('safeps')
			pathUtil = require('path')
			mkdirp = require('mkdirp')
			async = require('async')

			# Prepare
			docpad = @docpad
			config = @getConfig()
			docpadConfig = @docpad.getConfig()

			# Set out directory
			# the trailing / indicates to cp that the files of this directory should be copied over
			# rather than the directory itself
			outPath = pathUtil.normalize(docpadConfig.outPath)
			srcPath = pathUtil.normalize(docpadConfig.srcPath)
			# @TODO: why do we need to normalize these?

			if Object.keys(config).length is 0
				config.default = {}
				config.default.src = 'raw'

			eachr config, (target, key) ->
				config[key].name = key

			targets = (config[target] for target of config)

			iterator = (target, next) ->
				docpad.log("info", "Copying #{target.name}")

				target.src or= 'raw'
				target.out or= ''

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
					out = pathUtil.join(outPath, target.out)

					# Use ncp settings if specified
					options = if target.options? and typeof target.options is 'object' then target.options else {}

					docpad.log('debug', "raw plugin info... out: #{out}, src: #{src}, options: #{JSON.stringify(options)}")

					mkdirp.sync(out)

					ncp src, out, options, (err) ->
						return next(err) if err
						docpad.log('debug', "Done copying #{target.name}")
						return next()

			finished = (err) ->
				throw err if err
				next()

			async.each targets, iterator, finished
