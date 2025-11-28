project('dash-to-dock', 'c', meson_version: '>=0.60.0')

make = find_program('make')
d2d_src = meson.current_source_dir()

prefix = get_option('prefix')
meson.add_install_script(make, '-C', d2d_src, 'install', 'PREFIX="@0@"'.format(
    prefix))

if prefix != '/usr'
    sh = find_program('sh')
    meson.add_install_script(sh, '-xue', '-c',
        ';'.join([
            'mkdir -p "${DESTDIR}/@0@"',
            'cp -RT "${DESTDIR}"/usr/share ${DESTDIR}/@0@/share',
            'rm -rf "${DESTDIR}"/usr/share',
        ]).format(prefix))
endif

test('linting',
    make,
    workdir: d2d_src,
    args: [
        'check',
        'ESLINT_TAP=1',
    ],
    # protocol: 'tap',
)
