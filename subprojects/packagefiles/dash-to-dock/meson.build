project('dash-to-dock', 'c', meson_version: '>=0.60.0')

make = find_program('make')
d2d_src = meson.current_source_dir()

prefix = get_option('prefix')
meson.add_install_script(make, '-C', d2d_src, 'install', 'PREFIX="@0@"'.format(
    prefix))

sh = find_program('sh')

if prefix != '/usr'
    meson.add_install_script(sh, '-xue', '-c',
        ';'.join([
            'mkdir -p "${DESTDIR}/@0@"',
            'cp -RT "${DESTDIR}"/usr/share ${DESTDIR}/@0@/@1@',
            'rm -rf "${DESTDIR}"/usr/share',
        ]).format(prefix, get_option('datadir')))
endif

jq = find_program('jq', required: true)
metadata = files('metadata.json')

uuid = run_command(jq, '-r', '."uuid"', metadata).stdout().strip()

meson.add_install_script(sh, '-xue', '-c',
    ';'.join([
        'mkdir -p ${DESTDIR}/@1@',
        'cp @0@/ubuntu.css ${DESTDIR}/@1@',
    ]).format(
        meson.current_source_dir(),
        prefix / get_option('datadir') / 'gnome-shell' / 'extensions' / uuid,
    ))

install_data('schemas/10_ubuntu-dock.gschema.override',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas')

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
