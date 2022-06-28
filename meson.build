project(
	'bill',
	['d'],
	version: '0.0.0',
	license: [
		'Zlib',
	],
)

# Configure to support moss-format
# TODO: Allow moss-format to build *without* some components..
moss_vendor = subproject('moss-vendor',
    default_options: [
        'with_yaml=true',
		'with_elf=true',
		'with_xxhash=true',
		'with_zstd=true',
    ],
)

# Right now we'll only build against a local moss-core checkout
moss_core = subproject('moss-core')
link_libmoss_core = moss_core.get_variable('link_libmoss_core')

# Dep graph
moss_deps = subproject('moss-deps')
link_lib_moss_deps = moss_deps.get_variable('link_libmoss_deps')

# Parse recipes
moss_format = subproject('moss-format')
link_libmoss_format_source = moss_format.get_variable('link_libmoss_format_source')

# We use the same includes for everything..
global_includes = [
	include_directories('source')
]

# binary sources
bill_sources = [
	'source/bill/package.d',
	'source/bill/build_api.d',
	'source/bill/build_plugin.d',
	'source/bill/build_queue.d',
	'source/bill/build_worker.d',
	'source/bill/buildconf.d',
	'source/bill/stage.d',
	'source/app.d',
]

bill_deps = [
	link_libmoss_core,
	link_lib_moss_deps,
	link_libmoss_format_source,
]

# Compile as a static library
bill = executable(
	'bill',
	bill_sources,
	dependencies: bill_deps,
	install: true,
	include_directories: global_includes,
	link_args: '--link-defaultlib-shared=false',
	d_args: [
		'-preview=in',
		'-preview=dip1000',
	]
)
