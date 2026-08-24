project('myna-shell',
  version: '1',
  meson_version: '>= 0.63.0',
)

extension_path = '.'

jq = find_program('jq', required: true)
metadata = files(extension_path / 'metadata.json')
uuid = run_command(jq, '-r', '.uuid', metadata, check: true).stdout().strip()
extension_dir = get_option('datadir') / 'gnome-shell' / 'extensions' / uuid

install_subdir(extension_path,
  install_dir: extension_dir,
  strip_directory: true,
  exclude_files: ['meson.build'],
  exclude_directories: [
    'dev-lab',
    'test',
  ],
)

subdir('po')

summary({
  'Extension UUID': uuid,
  'Extension directory': extension_dir,
}, section: 'Configuration')
