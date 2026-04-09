project('dash-to-dock', 'c', meson_version: '>=0.60.0')

make = find_program('make')
d2d_src = meson.current_source_dir()

prefix = get_option('prefix')
share_dir = prefix / get_option('datadir')

sh = find_program('sh')
glib_compile_schemas = find_program('glib-compile-schemas')

jq = find_program('jq', required: true)
metadata = files('metadata.json')

uuid = run_command(jq, '-r', '."uuid" // empty', metadata, check: true).stdout().strip()
if uuid == ''
    error('metadata.json must define a non-empty "uuid"')
endif
extension_install_dir = share_dir / 'gnome-shell' / 'extensions' / uuid
locale_install_dir = prefix == '/usr' ? share_dir / 'locale' : extension_install_dir / 'locale'

meson.add_install_script(sh, '-xue', '-c',
    ';'.join([
        'source_dir="@0@"',
        'install_root="${DESTDIR:-}"',
        'make_destdir="$install_root"',
        'if [ -z "$make_destdir" ] || [ "@5@" != "/usr" ]; then make_destdir="$(mktemp -d)"; trap \'rm -rf "$make_destdir"\' EXIT; fi',
        'extension_install_dir="$install_root@2@"',
        'staged_extension_dir="$make_destdir/usr/share/gnome-shell/extensions/@6@"',
        'staged_schema_dir="$make_destdir/usr/share/glib-2.0/schemas"',
        'system_schema_dir="$install_root@1@/glib-2.0/schemas"',
        '"@3@" -C "$source_dir" install DESTDIR="$make_destdir"',
        'if [ "$make_destdir" != "$install_root" ]; then mkdir -p "$(dirname "$extension_install_dir")"; cp -RT "$staged_extension_dir" "$extension_install_dir"; fi',
        'if [ "@5@" = "/usr" ] && [ "$make_destdir" != "$install_root" ] && [ -d "$staged_schema_dir" ]; then mkdir -p "$system_schema_dir"; cp -R "$staged_schema_dir"/. "$system_schema_dir"/; fi',
        'mkdir -p "$extension_install_dir"',
        'cp "$source_dir/ubuntu.css" "$extension_install_dir"',
        'mkdir -p "$extension_install_dir/schemas"',
        'cp "$source_dir"/schemas/*.xml "$extension_install_dir/schemas"',
        'cp "$source_dir"/schemas/*.gschema.override "$extension_install_dir/schemas"',
        '"@4@" "$extension_install_dir/schemas"',
        'rm -f "$extension_install_dir/schemas/"*.gschema.override',
    ]).format(
        meson.current_source_dir(),
        share_dir,
        extension_install_dir,
        make.full_path(),
        glib_compile_schemas.full_path(),
        prefix,
        uuid,
    ))

test('linting',
    make,
    workdir: d2d_src,
    args: [
        'check',
        'ESLINT_TAP=1',
    ],
    # protocol: 'tap',
)

subdir('po')
