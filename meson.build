project(
	'bill',
	['d'],
	version: '0.0.0',
	license: [
		'Zlib',
	],
)


# Right now we'll only build against a local moss-core checkout
moss_core = subproject('moss-core')
link_libmoss_core = moss_core.get_variable('link_libmoss_core')

moss_deps = subproject('moss-deps')
link_lib_moss_deps = moss_deps.get_variable('link_libmoss_deps')

# We use the same includes for everything..
global_includes = [
	include_directories('source')
]

# binary sources
bill_sources = [
	'source/bill/package.d',
	'source/bill/buildconf.d',
	'source/bill/stage.d',
	'source/app.d',
]

bill_deps = [
	link_libmoss_core,
	link_lib_moss_deps,
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
