project('tiling-assistant', meson_version: '>=0.63.0')

src_dir = meson.current_source_dir()

extension_uuid = 'tiling-assistant@ubuntu.com'
source_extension_dir = 'tiling-assistant@leleat-on-github'

extension_install_dir = get_option('datadir') / 'gnome-shell' / 'extensions' / extension_uuid

metadata_file = 'metadata.json'
schemas_path = 'schemas'

jq = find_program('jq', required: true)

original_uuid = run_command(jq, '-r', '.uuid',
  source_extension_dir / metadata_file,
  check: true).stdout().strip()

install_subdir(
  source_extension_dir,
  install_dir: extension_install_dir,
  strip_directory: true,
  exclude_files: [metadata_file],
  exclude_directories: [schemas_path],
)

install_subdir(
  source_extension_dir / schemas_path,
  strip_directory: true,
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

custom_target(metadata_file,
  input: source_extension_dir / metadata_file,
  output: metadata_file,
  command: [
    jq, '-r',
    '.uuid = "@0@" | '.format(extension_uuid) +
    '.name = "Ubuntu Tiling Assistant" | ' +
    '."gettext-domain" = "@0@" | '.format(original_uuid) +
    '.url = "https://launchpad.net/ubuntu/+source/gnome-shell-extension-tiling-assistant"',
    '@INPUT@'
  ],
  capture: true,
  install: true,
  install_dir: extension_install_dir
)

subdir('translations')
