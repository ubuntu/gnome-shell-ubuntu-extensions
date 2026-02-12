project('gnome-shell-ubuntu-extensions', 'c',
  version: '0.1.0',
  meson_version: '>= 0.63.0'
)

extensions = {
  'appindicators': [
      'local_install=disabled',
  ],
  'desktop-icons-ng': [],
  'dash-to-dock': [],
  'snapd-prompting': [
      'local_install=disabled',
  ],
  'tiling-assistant': [],
}

foreach extension, options : extensions
  subproject(extension, default_options: options)
endforeach
